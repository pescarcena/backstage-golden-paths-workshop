# Paso 03: Golden Paths - Software Templates

En este paso configuramos los **Software Templates** (Golden Paths) en Backstage para scaffolding estandarizado de nuevos servicios.

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | Registra templates via ConfigMap + Deployment patch | `make all MODE=k8s` |
| **Local** | Registra templates via paths locales en app-config | `make all MODE=local` |

Los archivos del template (template.yaml + skeleton/) son compartidos entre ambos modos y se encuentran en `shared/templates/`.

## Kubernetes (default)

- [Instrucciones completas para Kubernetes](k8s/README.md)

## Local

- [Instrucciones completas para Local](local/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

---

**Paso anterior:** [02 - Deploy Backstage](../02-deploy-backstage/) | **Siguiente paso:** [04 - Backstage Kubernetes Plugin](../04-backstage-kubernetes-plugin/)
