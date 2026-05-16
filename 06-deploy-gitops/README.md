# Paso 06: Deploy GitOps con ArgoCD

Despliega ArgoCD en el cluster Kubernetes e integra el plugin de ArgoCD en Backstage.

## Modos disponibles

| Modo | Descripcion | Comando |
|------|-------------|---------|
| **Kubernetes** | ArgoCD + plugin Backstage via URL in-cluster | `make all MODE=k8s` |
| **Local** | ArgoCD + plugin Backstage via NodePort (localhost:30003) | `make all MODE=local` |

ArgoCD siempre corre en el cluster Kind. La diferencia entre modos es como Backstage se conecta a ArgoCD.

Los manifiestos compartidos de ArgoCD se encuentran en `shared/`.

## Kubernetes (default)

- [Instrucciones completas para Kubernetes](k8s/README.md)

## Local

- [Instrucciones completas para Local](local/README.md)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

---

**Paso anterior:** [05 - GitOps Conceptos](../05-gitops-conceptos/) | **Siguiente paso:** [07 - Seguridad SSO y Politicas](../07-seguridad-sso-politicas/)
