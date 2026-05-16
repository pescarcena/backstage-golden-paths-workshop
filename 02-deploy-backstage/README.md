# Paso 02: Desplegar Backstage

Este paso despliega Backstage junto con su base de datos PostgreSQL. Soporta dos modos de ejecucion:

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | Backstage corre como Deployment en el cluster Kind | `make all MODE=k8s` |
| **Local** | Backstage corre localmente con `yarn start` | `make all MODE=local` |

## Kubernetes (default)

Despliega Backstage y PostgreSQL como pods en el cluster Kind. Accesible via NodePort en `http://localhost:30000`.

- [Instrucciones completas para Kubernetes](k8s/README.md)

## Local

Corre PostgreSQL via Docker Compose y Backstage localmente con `yarn start`. Accesible en `http://localhost:3000`.

- [Instrucciones completas para Local](local/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind funcionando)
- **Modo K8s**: Solo kubectl
- **Modo Local**: Node.js 20+, Docker, tmux

---

**Paso anterior:** [01 - Kubernetes Local](../01-kubernetes-local/) | **Siguiente paso:** [03 - Golden Paths](../03-golden-paths/)
