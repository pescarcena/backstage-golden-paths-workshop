# Paso 08: RBAC Multi-Capa — Modo Kubernetes

## Que se configura

Este paso conecta la identidad del usuario (Keycloak) con los permisos reales en cada capa de la plataforma.

### Capas de seguridad

| Capa | Que controla | Como | Recurso |
|------|-------------|------|---------|
| **Backstage** | Acciones en la UI (crear, eliminar entidades) | Permission Framework | `permission-policy.ts` (paso 07) |
| **ArgoCD RBAC** | Que apps/proyectos puede ver y sincronizar | ConfigMap `argocd-rbac-cm` | `argocd-rbac-patch.yaml` |
| **ArgoCD AppProject** | A que namespaces puede desplegar | AppProject CRD | `argocd-projects.yaml` |
| **Kubernetes RBAC** | Que recursos puede crear/modificar en cada namespace | RoleBinding | `k8s-rbac-namespaced.yaml` |

### Mapeo de permisos

```
Keycloak                   ArgoCD                  Kubernetes
+------------------+       +------------------+    +------------------+
| grupo: developers| ----> | role: developer  |    | RoleBinding:     |
|                  |       |   get/sync solo  |    |   edit en        |
|                  |       |   en team-dev    |    |   apps-dev       |
+------------------+       +------------------+    +------------------+

+------------------+       +------------------+    +------------------+
| grupo:           | ----> | role: admin      |    | RoleBinding:     |
|  platform-team   |       |   acceso total   |    |   edit en        |
|                  |       |                  |    |   todos           |
+------------------+       +------------------+    +------------------+
```

## Modo automatico

```bash
make all
```

Esto ejecuta en orden:
1. Crea namespaces `apps-dev` y `apps-platform`
2. Aplica RoleBindings de K8s por namespace
3. Crea AppProjects en ArgoCD con destinos restringidos
4. Configura RBAC de ArgoCD (grupo Keycloak -> rol ArgoCD)
5. Conecta ArgoCD con Keycloak via OIDC
6. Registra entidades User/Group en el catalogo de Backstage

## Paso a paso manual

### 1. Crear namespaces de trabajo

```bash
make create-namespaces
# Crea: apps-dev (para developers) y apps-platform (para platform-team)
```

### 2. Aplicar K8s RBAC por namespace

```bash
make apply-k8s-rbac
```

Esto crea RoleBindings que limitan que puede hacer cada grupo en cada namespace:

| Grupo | apps-dev | apps-platform |
|-------|----------|---------------|
| developers | `edit` (crear, modificar, eliminar) | `view` (solo lectura) |
| platform-team | `edit` | `edit` |

### 3. Crear AppProjects en ArgoCD

```bash
make apply-argocd-projects
```

Los AppProjects restringen a que namespaces puede desplegar ArgoCD:

| AppProject | Destinos permitidos | Quien lo usa |
|------------|-------------------|--------------|
| `team-dev` | Solo `apps-dev` | developers |
| `team-platform` | Cualquier namespace | platform-team |

### 4. Configurar RBAC de ArgoCD

```bash
make apply-argocd-rbac
```

Mapea los grupos de Keycloak a roles de ArgoCD:

```csv
# Rol custom: developer
p, role:developer, applications, get, team-dev/*, allow
p, role:developer, applications, sync, team-dev/*, allow
p, role:developer, applications, create, team-dev/*, allow

# Mapeo de grupos
g, developers, role:developer
g, platform-team, role:admin
```

### 5. Conectar ArgoCD con Keycloak

```bash
make apply-argocd-oidc
```

Permite login en ArgoCD con las mismas credenciales de Keycloak (admin-user/dev-user).

### 6. Registrar organizacion en Backstage

```bash
make register-org
```

Crea entidades User y Group en el catalogo de Backstage para que el ownership y los permisos funcionen correctamente.

## Demo

### Probar como dev-user

```bash
make demo-dev
```

Demuestra:
1. **Deploy en apps-dev** -> OK (AppProject team-dev lo permite)
2. **Deploy en apps-platform** -> RECHAZADO por ArgoCD (destino no permitido en team-dev)
3. **kubectl directo en apps-platform** -> RECHAZADO por K8s RBAC (solo tiene `view`)

### Probar como admin-user

```bash
make demo-admin
```

Demuestra que admin-user puede operar en todas las capas sin restriccion.

### Probar en la UI

1. Abre ArgoCD: https://localhost:30003
2. Click "Log in via Keycloak"
3. Ingresa como `dev-user / dev123`
4. Solo veras las apps del proyecto `team-dev`
5. Cierra sesion e ingresa como `admin-user / admin123`
6. Veras todas las apps de todos los proyectos

## Por que Backstage no filtra namespaces en la UI?

El plugin de Kubernetes de Backstage usa un **ServiceAccount compartido** para todos los usuarios. No soporta filtrado per-usuario out-of-the-box. Implementar esto requiere:

- Custom `AuthenticationStrategy` que mapee grupos a ServiceAccounts
- O autenticacion client-side (OIDC passthrough al cluster)

En produccion, la seguridad no depende de lo que la UI muestra, sino de lo que las APIs permiten. Un usuario puede ver todos los namespaces en Backstage, pero ArgoCD y K8s RBAC impiden que opere fuera de su zona.

## Arquitectura de seguridad completa

```
+-------+     OIDC      +----------+
| User  | ------------> | Keycloak |  Identidad: "dev-user", grupos: ["developers"]
+-------+               +----------+
    |                         |
    |   Token OIDC            | Token OIDC
    |   (groups claim)        | (groups claim)
    v                         v
+----------+           +----------+            +----------+
| Backstage|           |  ArgoCD  |            |   K8s    |
|          |           |          |            |   API    |
| Permisos:|           | RBAC:    |            | RBAC:    |
| delete:  |           | dev ->   |            | dev ->   |
|  DENY    |           | team-dev |            | apps-dev |
|          |           |          |            |          |
| AppProject:          |          |
|          |           | team-dev |            |          |
|          |           | destino: |            |          |
|          |           | apps-dev |            |          |
+----------+           +----------+            +----------+
```

## Troubleshooting

### ArgoCD no acepta login via Keycloak
```bash
# Verificar que argocd-cm tiene la config OIDC
kubectl get configmap argocd-cm -n argocd -o yaml | grep oidc

# Verificar que Keycloak es accesible desde ArgoCD
kubectl exec -n argocd deployment/argocd-server -- \
  curl -s http://keycloak.keycloak.svc:8080/realms/backstage/.well-known/openid-configuration | head -1
```

### La Application se crea pero ArgoCD no la sincroniza
Revisa las condiciones de la Application:
```bash
kubectl get application demo-nginx-platform -n argocd -o jsonpath='{.status.conditions}' | jq .
```
Si el destino no esta permitido en el AppProject, veras un error como:
`application destination {https://kubernetes.default.svc apps-platform} is not permitted in project 'team-dev'`

### dev-user ve apps de todos los proyectos en ArgoCD
Verifica que el RBAC esta aplicado:
```bash
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
```
Debe contener las lineas `g, developers, role:developer`.

## Limpiar

```bash
make clean
```

---

**Paso anterior:** [07 - Seguridad SSO y Politicas](../../07-seguridad-sso-politicas/)
