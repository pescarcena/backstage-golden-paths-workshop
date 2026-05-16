# Paso 07: Seguridad SSO - Modo Local

En modo local, Keycloak corre via Docker Compose en `localhost:8180` y Backstage se configura para autenticar usuarios via OIDC (OpenID Connect).

## Modo automatico

```bash
make all
# Reinicia Backstage (Ctrl+C + make start-backstage desde el root)
```

## Pasos manuales (guia detallada)

Este paso modifica archivos tanto en el **backend** como en el **frontend** de Backstage. A continuacion se explica cada cambio y por que es necesario.

### 1. Desplegar Keycloak

```bash
docker compose up -d keycloak
```

Accede a http://localhost:8180 (admin / admin123).

El realm `backstage` se importa automaticamente desde `shared/keycloak-realm.json` con:
- Usuarios de prueba pre-configurados
- Client `backstage` con redirect URIs para localhost
- Client scopes `profile`, `email` y `groups` con sus protocol mappers

> **Importante:** Keycloak 26+ no crea automaticamente los scopes `profile` y `email` en realms importados.
> El archivo `keycloak-realm.json` los define explicitamente con sus protocol mappers
> para que el token OIDC incluya los claims `email`, `preferred_username`, `given_name` y `family_name`.

### 2. Backend: Instalar modulo OIDC

```bash
cd ../../02-deploy-backstage/local/backstage-app
yarn --cwd packages/backend add @backstage/plugin-auth-backend-module-oidc-provider
```

**Por que:** Este paquete registra el provider `oidc` en el backend de Backstage, habilitando los endpoints `/api/auth/oidc/start`, `/api/auth/oidc/handler` y `/api/auth/oidc/refresh`.

### 3. Backend: Registrar el modulo en index.ts

En `packages/backend/src/index.ts`, agrega:

```typescript
backend.add(import('@backstage/plugin-auth-backend-module-oidc-provider'));
```

Y **elimina** la linea del guest-provider:

```typescript
// ELIMINAR esta linea:
backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));
```

**Por que:** El guest-provider permite acceso sin login en modo development.
Si se deja activo, Backstage nunca pide credenciales.

### 4. Backend: Configurar OIDC (app-config.auth.yaml)

Copia `app-config.auth.yaml` al directorio de Backstage:

```bash
cp app-config.auth.yaml ../../02-deploy-backstage/local/backstage-app/
```

Este archivo contiene:

```yaml
auth:
  environment: development
  providers:
    oidc:
      development:
        metadataUrl: http://localhost:8180/realms/backstage/.well-known/openid-configuration
        clientId: backstage
        clientSecret: ${KEYCLOAK_CLIENT_SECRET:-backstage-workshop-secret}
        prompt: auto
        signIn:
          resolvers:
            - resolver: emailMatchingUserEntityProfileEmail
              options:
                dangerouslyAllowSignInWithoutUserInCatalog: true
```

**Notas de configuracion (lecciones aprendidas con esta version):**

| Config | Valor correcto | Error comun | Motivo |
|--------|---------------|-------------|--------|
| `scope` | NO usar | `scope: 'openid profile email'` | Deprecado. Los scopes basicos se envian automaticamente. Para scopes extra usar `additionalScopes` |
| Resolver | `emailMatchingUserEntityProfileEmail` | `preferredUsernameMatchingUserEntityName` | No existe en el modulo OIDC. Solo hay `emailMatchingUserEntityProfileEmail` y `emailLocalPartMatchingUserEntityName` |
| `dangerouslyAllowSignInWithoutUserInCatalog` | `true` (workshop) | omitir | Sin esto, cada usuario de Keycloak necesita una entidad User en el catalogo de Backstage |

**Sobre `dangerouslyAllowSignInWithoutUserInCatalog`:**
- En **workshop/dev**: Usar `true` para que cualquier usuario de Keycloak pueda hacer login
- En **produccion**: Usar `false` e instalar `@backstage/plugin-catalog-backend-module-keycloak` para sincronizar usuarios automaticamente

### 5. Frontend: Crear modulo de autenticacion (3 archivos TSX/TS)

El frontend de Backstage usa el nuevo sistema declarativo (`@backstage/frontend-defaults`).
En este sistema, la pagina de sign-in es una **extension** que se registra via codigo, no via YAML.

**Por que no basta con YAML:** El `DefaultSignInPage` de `@backstage/plugin-app` esta hardcodeado con `providers: ['guest']`. No hay config YAML que lo cambie. Para usar OIDC se necesita crear una extension custom.

#### 5a. `packages/app/src/modules/auth/oidcAuth.ts`

```typescript
import {
  createApiRef,
  OpenIdConnectApi,
  ProfileInfoApi,
  BackstageIdentityApi,
  SessionApi,
} from '@backstage/core-plugin-api';

export const oidcAuthApiRef = createApiRef<
  OpenIdConnectApi & ProfileInfoApi & BackstageIdentityApi & SessionApi
>({
  id: 'internal.auth.oidc',
});
```

**Por que:** Define la referencia a la API que maneja el flujo OAuth2 con Keycloak.
El `SignInPage` necesita un `apiRef` para saber como autenticar al usuario.

#### 5b. `packages/app/src/modules/auth/SignInPage.tsx`

```tsx
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import { SignInPage } from '@backstage/core-components';
import { oidcAuthApiRef } from './oidcAuth';

export const oidcSignInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props => (
      <SignInPage
        {...props}
        provider={{
          id: 'oidc-auth-provider',
          title: 'Keycloak',
          message: 'Sign in with your Keycloak account',
          apiRef: oidcAuthApiRef,
        }}
      />
    ),
  },
});
```

**Por que:** Crea la extension de sign-in page que reemplaza al `DefaultSignInPage` (guest).

Notas importantes:
- Se usa `provider` (singular, objeto) en vez de `providers` (array). Esto activa `SingleSignInPage` que intenta login automaticamente
- **NO se pone `name`** en `SignInPageBlueprint.make()`. Sin nombre, la extension obtiene el ID `sign-in-page:app` (igual que el default) y lo **reemplaza** automaticamente via el sistema de modulos
- `apiRef: oidcAuthApiRef` es obligatorio. Sin el, el componente falla con `Cannot read properties of undefined (reading 'id')`

#### 5c. `packages/app/src/modules/auth/index.ts`

```typescript
import {
  createFrontendModule,
  ApiBlueprint,
} from '@backstage/frontend-plugin-api';
import {
  discoveryApiRef,
  oauthRequestApiRef,
  configApiRef,
} from '@backstage/core-plugin-api';
import { OAuth2 } from '@backstage/core-app-api';
import { oidcSignInPage } from './SignInPage';
import { oidcAuthApiRef } from './oidcAuth';

const oidcAuthApi = ApiBlueprint.make({
  name: 'oidc-auth',
  params: defineParams =>
    defineParams({
      api: oidcAuthApiRef,
      deps: {
        discoveryApi: discoveryApiRef,
        oauthRequestApi: oauthRequestApiRef,
        configApi: configApiRef,
      },
      factory: ({ discoveryApi, oauthRequestApi, configApi }) =>
        OAuth2.create({
          configApi,
          discoveryApi,
          oauthRequestApi,
          provider: {
            id: 'oidc',        // DEBE coincidir con el providerId del backend
            title: 'Keycloak',
            icon: () => null,
          },
          defaultScopes: ['openid', 'profile', 'email'],
        }),
    }),
});

export const authModule = createFrontendModule({
  pluginId: 'app',
  extensions: [oidcSignInPage, oidcAuthApi],
});
```

**Por que:** Registra dos cosas:
1. La extension de sign-in page (reemplaza al guest)
2. La API factory que crea el cliente OAuth2 (`OAuth2.create`)

Notas:
- `provider.id: 'oidc'` debe coincidir con el `providerId` del backend (registrado por `plugin-auth-backend-module-oidc-provider`)
- `ApiBlueprint.make` requiere `params` como **funcion** (`defineParams => defineParams({...})`), no como objeto. Esto es diferente de la mayoria de APIs de Backstage
- `pluginId: 'app'` es necesario porque el input `signInPage` del `app/root` esta marcado como `internal`. Solo extensiones del plugin `app` pueden proveerlo

### 6. Frontend: Registrar modulo en App.tsx

En `packages/app/src/App.tsx`:

```typescript
import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { navModule } from './modules/nav';
import { authModule } from './modules/auth';    // <- agregar

export default createApp({
  features: [catalogPlugin, navModule, authModule],  // <- agregar authModule
});
```

**Por que:** El modulo debe registrarse en `createApp` para que Backstage descubra las extensiones y las integre en el arbol de la aplicacion.

## Resumen de archivos modificados

| Archivo | Tipo de cambio | Motivo |
|---------|---------------|--------|
| `packages/backend/src/index.ts` | Agregar OIDC, quitar guest | Habilitar auth OIDC en el backend |
| `app-config.auth.yaml` | Nuevo archivo | Config OIDC: Keycloak URL, client, resolver |
| `packages/app/src/modules/auth/oidcAuth.ts` | Nuevo archivo | API ref para el cliente OAuth2 |
| `packages/app/src/modules/auth/SignInPage.tsx` | Nuevo archivo | Sign-in page con Keycloak (reemplaza guest) |
| `packages/app/src/modules/auth/index.ts` | Nuevo archivo | Modulo frontend: API factory + sign-in page |
| `packages/app/src/App.tsx` | Agregar import | Registrar el modulo de auth |

## Flujo de autenticacion

```
Usuario abre localhost:3000
    |
    v
Frontend: SignInPage (OIDC) se muestra
    |
    v
Click "SIGN IN" -> Frontend llama /api/auth/oidc/start
    |
    v
Backend redirige a Keycloak (localhost:8180)
    |
    v
Usuario ingresa credenciales en Keycloak
    |
    v
Keycloak redirige a /api/auth/oidc/handler con codigo
    |
    v
Backend intercambia codigo por token, extrae email del token
    |
    v
Resolver busca User entity con ese email en el catalogo
(o crea referencia temporal si dangerouslyAllowSignInWithoutUserInCatalog: true)
    |
    v
Backend emite Backstage token -> Frontend autenticado
```

## Usuarios de prueba

| Usuario | Password | Grupo | Rol |
|---------|----------|-------|-----|
| admin-user | admin123 | platform-team | backstage-admin |
| dev-user | dev123 | developers | backstage-user |

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| Keycloak | Docker Compose (localhost:8180) | Deployment K8s (NodePort 30004) |
| OIDC module | Instalado via yarn | Incluido en imagen Docker |
| Secrets | Variables de entorno / .env | K8s Secret |
| OIDC URL | localhost:8180 | keycloak.keycloak.svc:8080 |

## Produccion: sincronizar usuarios automaticamente

En produccion, en vez de `dangerouslyAllowSignInWithoutUserInCatalog`, instala el modulo de catalogo para Keycloak:

```bash
yarn --cwd packages/backend add @backstage/plugin-catalog-backend-module-keycloak
```

```typescript
// packages/backend/src/index.ts
backend.add(import('@backstage/plugin-catalog-backend-module-keycloak'));
```

```yaml
# app-config.yaml
catalog:
  providers:
    keycloak:
      default:
        baseUrl: https://keycloak.example.com
        realm: backstage
        schedule:
          frequency: { minutes: 30 }
          timeout: { minutes: 3 }
```

Esto sincroniza usuarios y grupos de Keycloak al catalogo de Backstage automaticamente.
