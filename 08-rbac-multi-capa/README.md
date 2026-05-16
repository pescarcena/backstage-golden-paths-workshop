# Paso 08: RBAC Multi-Capa — Del Login al Deploy

Configura control de acceso en **todas las capas** de la plataforma: Backstage, ArgoCD y Kubernetes. Demuestra que la seguridad no depende de esconder botones en la UI, sino de que cada capa valide independientemente.

## Que enseña este paso

```
                    dev-user (Keycloak: grupo "developers")
                              |
            +-----------------+-----------------+
            v                 v                 v
     +----------+      +----------+      +----------+
     | Backstage|      |  ArgoCD  |      | K8s RBAC |
     |Permission|      |AppProject|      |RoleBinding|
     | Framework|      |          |      |          |
     |          |      | destinos:|      |namespace: |
     | delete:  |      | apps-dev |      | apps-dev  |
     |  DENY    |      | ONLY     |      | ONLY      |
     +----------+      +----------+      +----------+
         UI              GitOps           Cluster
     "no puedes       "no puedes        "no puedes
      borrar"          sync aqui"        crear aqui"
```

**Mensaje clave**: La seguridad real es defensa en profundidad — cada capa valida independientemente.

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | Todo en el cluster Kind | `make all MODE=k8s` |
| **Local** | Backstage local, RBAC y ArgoCD en Kind | `make all MODE=local` |

## Kubernetes (default)

- [Instrucciones completas para Kubernetes](k8s/README.md)

## Local

- [Instrucciones completas para Local](local/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)
- Paso 06 completado (ArgoCD desplegado)
- Paso 07 completado (Keycloak + SSO configurado)

---

**Paso anterior:** [07 - Seguridad SSO y Politicas](../07-seguridad-sso-politicas/)
