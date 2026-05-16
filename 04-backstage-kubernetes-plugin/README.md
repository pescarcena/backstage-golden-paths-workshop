# Paso 04: Backstage Kubernetes Plugin

Configura el plugin de Kubernetes en Backstage para visualizar workloads del cluster directamente desde el catalogo.

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | Plugin con auth via ServiceAccount (in-cluster) | `make all MODE=k8s` |
| **Local** | Plugin con auth via kubeconfig (local) | `make all MODE=local` |

El RBAC (ClusterRole + ClusterRoleBinding) es compartido entre ambos modos y se encuentra en `shared/k8s-rbac.yaml`.

## Kubernetes (default)

- [Instrucciones completas para Kubernetes](k8s/README.md)

## Local

- [Instrucciones completas para Local](local/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

---

**Paso anterior:** [03 - Golden Paths](../03-golden-paths/) | **Siguiente paso:** [05 - GitOps Conceptos](../05-gitops-conceptos/)
