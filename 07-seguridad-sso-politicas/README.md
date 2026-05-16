# Paso 07: Seguridad - SSO con Keycloak (OIDC)

Configura autenticacion con Keycloak como Identity Provider via OIDC (OpenID Connect), reemplazando el acceso guest por defecto.

## Que se configura

Este paso toca tanto el **backend** como el **frontend** de Backstage:

- **Backend:** Se instala el modulo OIDC que crea los endpoints de autenticacion (`/api/auth/oidc/*`) y se elimina el guest-provider
- **Frontend:** Se crea un modulo con la pagina de sign-in personalizada y el cliente OAuth2. Esto es necesario porque el `DefaultSignInPage` de Backstage esta hardcodeado con `providers: ['guest']` y no se puede cambiar via YAML
- **Keycloak:** Se despliega como IdP con un realm pre-configurado con usuarios, grupos, roles y client scopes

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | Keycloak en K8s + imagen custom con OIDC + Secrets K8s | `make all MODE=k8s` |
| **Local** | Keycloak via Docker Compose + .env file | `make all MODE=local` |

La configuracion del realm de Keycloak y el modulo de auth del frontend son compartidos entre ambos modos y se encuentran en `shared/`.

## Estructura de archivos

```
07-seguridad-sso-politicas/
  shared/
    keycloak-realm.json          # Realm: usuarios, grupos, client, scopes
    auth-module/                 # Modulo frontend (TSX/TS)
      oidcAuth.ts                # API ref para OAuth2
      SignInPage.tsx             # Sign-in page (reemplaza guest)
      index.ts                   # Modulo: API factory + sign-in page
    permission-policy.ts         # Politicas de permisos
  local/
    docker-compose.yaml          # Keycloak container
    app-config.auth.yaml         # Config OIDC para Backstage
    Makefile                     # Automatizacion
    README.md                    # Guia detallada paso a paso
  k8s/
    Dockerfile.backstage         # Imagen custom con modulo OIDC
    ...                          # Manifiestos para Kubernetes
```

## Instrucciones detalladas

- [Instrucciones para modo Local](local/README.md) - Incluye guia paso a paso con explicacion de cada archivo
- [Instrucciones para modo Kubernetes](k8s/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

---

**Paso anterior:** [06 - Deploy GitOps (ArgoCD)](../06-deploy-gitops/) | **Paso siguiente:** [08 - RBAC Multi-Capa](../08-rbac-multi-capa/)
