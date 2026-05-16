# Paso 07: Seguridad - SSO, IdP y Politicas de Acceso

En este paso vamos a configurar la **autenticacion** y **autorizacion** en Backstage. Implementaremos dos proveedores de identidad (GitHub OAuth y Keycloak) y definiremos politicas de acceso basadas en roles.

## Conceptos clave

### Autenticacion vs Autorizacion

```
AUTENTICACION (AuthN)                AUTORIZACION (AuthZ)
"Quien eres?"                        "Que puedes hacer?"

┌──────────────┐                     ┌──────────────┐
│   Login      │                     │  Permisos    │
│              │                     │              │
│ ┌──────────┐ │                     │ admin: CRUD  │
│ │ GitHub   │ │                     │ dev:   CR    │
│ │ OAuth    │ │                     │ guest: R     │
│ └──────────┘ │                     │              │
│ ┌──────────┐ │                     │ Basado en:   │
│ │ Keycloak │ │                     │ - Roles      │
│ │ OIDC     │ │                     │ - Grupos     │
│ └──────────┘ │                     │ - Ownership  │
└──────────────┘                     └──────────────┘
```

### Arquitectura de seguridad en Backstage

```
┌────────────────────────────────────────────────────────────┐
│                    BACKSTAGE                                │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                Auth Framework                        │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │    │
│  │  │ GitHub   │  │ Keycloak │  │ Sign-in          │   │    │
│  │  │ Provider │  │ Provider │  │ Resolvers        │   │    │
│  │  │ (OAuth)  │  │ (OIDC)   │  │ (user mapping)   │   │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
│                           │                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Permission Framework                    │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────┐  │    │
│  │  │ Permission   │  │ Policy       │  │ Conditions│  │    │
│  │  │ Rules        │  │ Decision     │  │ (filters) │  │    │
│  │  └──────────────┘  └──────────────┘  └───────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────────┘
                    │                  │
        ┌───────────┘                  └───────────┐
        ▼                                          ▼
┌──────────────┐                          ┌──────────────┐
│   GitHub     │                          │  Keycloak    │
│   OAuth      │                          │  (IdP local) │
│              │                          │              │
│  - Simple    │                          │  - Enterprise│
│  - Externo   │                          │  - RBAC      │
│  - Rapido    │                          │  - Grupos    │
└──────────────┘                          └──────────────┘
```

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)
- (Opcional) Cuenta de GitHub para OAuth

## Modo automatico

```bash
# Desplegar Keycloak + configurar auth + permisos
make all

# Para GitHub OAuth, ejecuta ademas:
make configure-github-auth
```

## Opcion A: GitHub OAuth (rapido)

GitHub OAuth es la forma mas rapida de agregar autenticacion a Backstage.

### 1. Crear OAuth App en GitHub

1. Ve a https://github.com/settings/developers
2. Click en **"OAuth Apps"** > **"New OAuth App"**
3. Rellena:
   - **Application name**: `Backstage Workshop`
   - **Homepage URL**: `http://localhost:30000`
   - **Authorization callback URL**: `http://localhost:30000/api/auth/github/handler/frame`
4. Click en **"Register application"**
5. Copia el **Client ID**
6. Genera un **Client Secret** y copialo

### 2. Configurar el Secret en Kubernetes

Edita `backstage-auth-secret.yaml` con tus valores:

```yaml
stringData:
  GITHUB_OAUTH_CLIENT_ID: "tu-client-id-real"
  GITHUB_OAUTH_CLIENT_SECRET: "tu-client-secret-real"
```

Aplica el secret:

```bash
kubectl apply -f backstage-auth-secret.yaml
```

### 3. Aplicar configuracion de auth

La configuracion esta en `app-config-auth.yaml`:

```yaml
auth:
  session:
    secret: ${AUTH_SESSION_SECRET}    # Requerido para OIDC
  providers:
    github:
      development:
        clientId: ${GITHUB_OAUTH_CLIENT_ID}
        clientSecret: ${GITHUB_OAUTH_CLIENT_SECRET}
        signIn:
          resolvers:
            - resolver: usernameMatchingUserEntityName
```

```bash
kubectl create configmap backstage-auth-config \
  --from-file=app-config-auth.yaml \
  -n backstage \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. Reiniciar Backstage

```bash
kubectl rollout restart deployment/backstage -n backstage
```

### 5. Verificar

Abre Backstage (http://localhost:30000). Deberia mostrar un boton de "Sign in with GitHub".

## Opcion B: Keycloak (IdP Enterprise)

Keycloak es un Identity Provider (IdP) completo que corre en tu cluster. Ofrece:
- Gestion completa de usuarios y grupos
- Multiples protocolos (OIDC, SAML)
- Federation con LDAP/Active Directory
- Politicas de passwords, MFA, etc.

### 1. Desplegar Keycloak

```bash
# Primero el ConfigMap con la configuracion del Realm
kubectl apply -f keycloak-realm.yaml

# Luego el Deployment y Service
kubectl apply -f keycloak-deployment.yaml
```

Esperar a que este listo:

```bash
kubectl wait --namespace keycloak \
  --for=condition=ready pod \
  --selector=app=keycloak \
  --timeout=300s
```

### 2. Verificar Keycloak

Abre http://localhost:30004 e ingresa con:
- **Usuario**: `admin`
- **Password**: `admin123`

Navega a **Realm: backstage** y verifica:
- **Users**: admin-user, dev-user
- **Groups**: platform-team, developers
- **Clients**: backstage (con los redirect URIs correctos)

### 3. Usuarios de prueba pre-configurados

| Usuario | Password | Grupo | Rol |
|---------|----------|-------|-----|
| admin-user | admin123 | platform-team | backstage-admin |
| dev-user | dev123 | developers | backstage-user |

### 4. Construir imagen custom de Backstage con OIDC

> **Importante**: La imagen oficial `ghcr.io/backstage/backstage` NO incluye el modulo OIDC.
> Es necesario construir una imagen custom que lo incluya.

```bash
# Construir imagen con el modulo OIDC
docker build -f k8s/Dockerfile.backstage -t backstage-workshop:oidc .

# Cargar imagen en el cluster Kind
kind load docker-image backstage-workshop:oidc --name backstage-workshop

# Actualizar el deployment con la imagen custom
kubectl set image deployment/backstage backstage=backstage-workshop:oidc -n backstage
kubectl patch deployment backstage -n backstage \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"backstage","imagePullPolicy":"Never"}]}}}}'
```

> **Nota**: `imagePullPolicy: Never` es necesario para que Kind use la imagen local en vez de intentar descargarla de un registry.

### 5. Configurar Backstage para usar Keycloak

La configuracion OIDC esta en `app-config.auth.yaml`:

```yaml
auth:
  session:
    secret: ${AUTH_SESSION_SECRET}    # Requerido para OIDC
  providers:
    oidc:
      development:
        metadataUrl: http://keycloak.keycloak.svc:8080/realms/backstage/.well-known/openid-configuration
        clientId: backstage
        clientSecret: ${KEYCLOAK_CLIENT_SECRET}
        prompt: auto
        signIn:
          resolvers:
            - resolver: emailMatchingUserEntityProfileEmail
              options:
                dangerouslyAllowSignInWithoutUserInCatalog: true
```

**Notas de configuracion:**

| Config | Valor correcto | Error comun | Motivo |
|--------|---------------|-------------|--------|
| `scope` | NO usar | `scope: 'openid profile email'` | Deprecado. Los scopes basicos se envian automaticamente |
| Resolver | `emailMatchingUserEntityProfileEmail` | `preferredUsernameMatchingUserEntityName` | No existe en el modulo OIDC |
| `dangerouslyAllowSignInWithoutUserInCatalog` | `true` (workshop) | omitir | Sin esto, cada usuario necesita una entidad User en el catalogo |

Aplicar:

```bash
# Aplicar secret con credenciales de auth
kubectl apply -f backstage-auth-secret.yaml

# Crear ConfigMap con la config de auth
kubectl create configmap backstage-auth-config \
  --from-file=app-config.auth.yaml \
  -n backstage \
  --dry-run=client -o yaml | kubectl apply -f -

# Reiniciar Backstage
kubectl rollout restart deployment/backstage -n backstage
```

## Politicas de acceso (Permission Framework)

### Como funciona?

Backstage tiene un **Permission Framework** que permite controlar que acciones puede hacer cada usuario:

```
Request: "dev-user quiere eliminar mi-servicio del catalogo"
         │
         ▼
┌─────────────────────────────┐
│    Permission Policy        │
│                             │
│  1. Es admin? → NO          │
│  2. Accion = delete? → SI   │
│  3. Solo admins eliminan    │
│                             │
│  Resultado: DENY            │
└─────────────────────────────┘
```

### Permisos disponibles en Backstage

| Permiso | Descripcion |
|---------|-------------|
| `catalog.entity.create` | Crear entidades en el catalogo |
| `catalog.entity.delete` | Eliminar entidades |
| `catalog.entity.refresh` | Refrescar entidades |
| `catalog.location.create` | Crear locations |
| `catalog.location.delete` | Eliminar locations |
| `scaffolder.action.execute` | Ejecutar templates |

### Nuestra politica de permisos

Revisa `../shared/permission-policy.ts`:

```typescript
import { AuthorizeResult } from '@backstage/plugin-permission-common';

// Regla 1: platform-team puede hacer todo
if (userGroups.includes('group:default/platform-team')) {
  return { result: AuthorizeResult.ALLOW };
}

// Regla 2: Nadie mas puede eliminar entidades
if (request.permission.name === catalogEntityDeletePermission.name) {
  return { result: AuthorizeResult.DENY };
}

// Regla 3: Todos pueden crear
if (request.permission.name === catalogEntityCreatePermission.name) {
  return { result: AuthorizeResult.ALLOW };
}
```

### Implementar la politica

> **Nota importante**: La politica de permisos es **codigo de referencia**. Para aplicarla en produccion,
> necesitas crear una imagen custom de Backstage que incluya este modulo compilado.
> En este workshop, los permisos estan deshabilitados para simplificar la demo.

La politica se registra como un modulo del backend usando el **New Backend System**:

1. Copia `permission-policy.ts` al proyecto de Backstage
2. Registra el modulo en `packages/backend/src/index.ts`
3. Habilita permisos en `app-config.yaml`
4. Reconstruye la imagen de Backstage

```yaml
# app-config.yaml
permission:
  enabled: true
```

```typescript
// packages/backend/src/index.ts
import { createBackend } from '@backstage/backend-defaults';
import permissionPolicy from './plugins/permission-policy';

const backend = createBackend();
// ... otros plugins ...
backend.add(import('@backstage/plugin-permission-backend'));
backend.add(permissionPolicy);
backend.start();
```

> **Nota**: La politica se implementa con `createBackendModule` y `policyExtensionPoint` (ver el archivo `permission-policy.ts` completo). En un workshop, es ilustrativa; para aplicarla necesitas una imagen custom de Backstage.

## Pruebas de acceso

```bash
make test-access
```

Verifica estos escenarios:

1. **Sin login**: Acceso denegado, redirige a login
2. **admin-user** (via Keycloak): Puede crear, editar y eliminar entidades
3. **dev-user** (via Keycloak): Puede crear y editar, NO puede eliminar
4. **GitHub user**: Puede crear y editar (segun la politica)

## Resumen de la arquitectura de seguridad

```
┌──────────────────────────────────────────────────────────┐
│                    BACKSTAGE                              │
│                                                           │
│  Auth Providers          Permission Framework             │
│  ┌────────────┐          ┌─────────────────────┐          │
│  │ GitHub     │          │ platform-team: ALL   │          │
│  │ OAuth      │─────────▶│ developers:    CR    │          │
│  └────────────┘          │ guest:         DENY  │          │
│  ┌────────────┐          └─────────────────────┘          │
│  │ Keycloak   │                                           │
│  │ OIDC       │──────────▶ Grupos → Roles → Permisos     │
│  └────────────┘                                           │
└──────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  ┌──────────────┐          ┌──────────────┐
  │ GitHub       │          │ Keycloak     │
  │ (externo)    │          │ (local)      │
  │              │          │ :30004       │
  └──────────────┘          └──────────────┘
```

## Troubleshooting

### Keycloak no inicia
```bash
kubectl logs -n keycloak -l app=keycloak -f
```
Causa comun: falta de recursos. Verifica que tu cluster tiene suficiente RAM.

### "Invalid redirect URI" al hacer login
Verifica que los redirect URIs en Keycloak coinciden con la URL de Backstage:
1. Abre Keycloak > Realm: backstage > Clients > backstage
2. Verifica "Valid redirect URIs" incluye tu URL

### El login funciona pero no mapea los grupos
Verifica que el scope "groups" esta habilitado en el client de Keycloak y que el claim mapper esta configurado.

### GitHub OAuth: "redirect_uri_mismatch"
La callback URL en GitHub debe ser exactamente:
`http://localhost:30000/api/auth/github/handler/frame`

## Limpiar

```bash
make clean
# O manualmente:
kubectl delete namespace keycloak
kubectl delete secret backstage-auth-secrets -n backstage
kubectl delete configmap backstage-auth-config -n backstage
```

---

**Paso anterior:** [06 - Deploy GitOps (ArgoCD)](../06-deploy-gitops/) | **Paso siguiente:** [08 - RBAC Multi-Capa](../../08-rbac-multi-capa/)
