# Paso 04: Backstage Kubernetes Plugin - Modo Local

En modo local, Backstage se conecta al cluster Kind usando tu kubeconfig local en lugar de un ServiceAccount in-cluster.

## Modo automatico

```bash
make all
# Reinicia Backstage para aplicar los cambios
```

## Como funciona

1. **RBAC**: Se aplica el mismo ClusterRole/ClusterRoleBinding que en modo K8s (shared)
2. **Auth**: En lugar de `serviceAccount` (in-cluster), usa `kubeconfig` (tu ~/.kube/config local)
3. **URL del cluster**: Se detecta automaticamente desde tu kubeconfig activo

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| Auth | kubeconfig (~/.kube/config) | ServiceAccount (in-cluster) |
| URL cluster | Detectada desde kubeconfig | https://kubernetes.default.svc |
| RBAC | Mismo (shared) | Mismo (shared) |
