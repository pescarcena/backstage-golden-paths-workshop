# Paso 08: RBAC Multi-Capa — Modo Local

K8s RBAC y ArgoCD siempre corren en el cluster Kind (igual que en modo k8s). La unica diferencia es que Backstage corre localmente con `yarn start`.

## Modo automatico

```bash
make all
```

Esto hace:
1. Crea namespaces `apps-dev` y `apps-platform` en el cluster
2. Aplica RoleBindings de K8s por namespace
3. Crea AppProjects en ArgoCD con destinos restringidos
4. Configura RBAC de ArgoCD (grupo Keycloak -> rol ArgoCD)
5. Conecta ArgoCD con Keycloak via OIDC
6. Copia `org.yaml` al proyecto Backstage local

## Demo

```bash
make demo-dev      # Simular permisos de dev-user
make demo-admin    # Simular permisos de admin-user
```

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| K8s RBAC | En el cluster Kind (igual) | En el cluster Kind (igual) |
| ArgoCD | En el cluster Kind (igual) | En el cluster Kind (igual) |
| Org catalog | org.yaml copiado al proyecto | ConfigMap en K8s |
| Backstage | yarn start (localhost:3000) | Pod (localhost:30000) |

## Probar en la UI de ArgoCD

1. Abre https://localhost:30003
2. Click "Log in via Keycloak"
3. Ingresa como `dev-user / dev123` -> solo ve proyecto `team-dev`
4. Ingresa como `admin-user / admin123` -> ve todos los proyectos
