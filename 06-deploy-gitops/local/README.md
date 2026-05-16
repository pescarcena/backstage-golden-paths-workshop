# Paso 06: Deploy GitOps con ArgoCD - Modo Local

ArgoCD se instala en el cluster Kind y se accede via su propia UI en `https://localhost:30003`.

## Modo automatico

```bash
make all
```

Esto hace:
1. Instala ArgoCD en el cluster Kind (namespace `argocd`)
2. Expone ArgoCD via NodePort (https://localhost:30003)
3. Guarda la config de conexion para Backstage

## Acceso a ArgoCD

```bash
# Ver credenciales
make get-password
```

- **URL**: https://localhost:30003 (acepta certificado auto-firmado)
- **Usuario**: admin
- **Password**: generada automaticamente (ver con `make get-password`)

## Nota sobre integracion con Backstage

En este paso, ArgoCD se gestiona desde su propia UI. La integracion con Backstage (ver sync status desde el catalogo) requiere plugins adicionales de la comunidad que no se instalan automaticamente en este workshop.

La config `app-config.argocd.yaml` se guarda en el proyecto Backstage para futuro uso si se instala el plugin.

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| ArgoCD | En el cluster Kind (igual) | En el cluster Kind (igual) |
| Acceso | https://localhost:30003 | https://localhost:30003 |
| Config Backstage | app-config.argocd.yaml guardada | ConfigMap en K8s |
