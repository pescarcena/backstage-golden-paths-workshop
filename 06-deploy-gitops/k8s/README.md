# Paso 06: Deploy GitOps con ArgoCD

En este paso vamos a desplegar **ArgoCD** en nuestro cluster de Kubernetes e integrarlo con Backstage para tener visibilidad del estado de los deployments.

## Conceptos clave

### Que es ArgoCD?

ArgoCD es un **controlador de entrega continua declarativo** para Kubernetes. Monitorea repositorios Git y sincroniza automaticamente los manifiestos con el cluster.

```
┌──────────────────────────────────────────────────────┐
│                      ArgoCD                           │
│                                                       │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │ Repo     │     │ App      │     │ Sync     │      │
│  │ Server   │────▶│Controller│────▶│ Engine   │      │
│  │          │     │          │     │          │      │
│  │ Conecta  │     │ Compara  │     │ Aplica   │      │
│  │ con Git  │     │ deseado  │     │ cambios  │      │
│  │          │     │ vs actual│     │ al       │      │
│  │          │     │          │     │ cluster  │      │
│  └──────────┘     └──────────┘     └──────────┘      │
│        │                │                │            │
│        ▼                ▼                ▼            │
│  ┌──────────┐     ┌──────────┐     ┌──────────┐      │
│  │ Git      │     │ Estado   │     │ K8s API  │      │
│  │ Repos    │     │ Desired  │     │ Server   │      │
│  │          │     │ vs Live  │     │          │      │
│  └──────────┘     └──────────┘     └──────────┘      │
│                                                       │
│  ┌─────────────────────────────────────────────┐      │
│  │            UI Web (Dashboard)                │      │
│  │  Apps | Sync Status | Health | Diff | Logs  │      │
│  └─────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────┘
```

### Conceptos de ArgoCD

- **Application**: Recurso que conecta un repo Git con un namespace de K8s
- **Project**: Agrupacion logica de Applications (permisos, restricciones)
- **Sync**: Proceso de aplicar los cambios de Git al cluster
- **Health**: Estado de salud de los recursos (Healthy, Degraded, Progressing)
- **Sync Status**: Si el cluster coincide con Git (Synced, OutOfSync)

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

## Modo automatico

```bash
# Instalar y configurar todo
make all

# Ver la password de ArgoCD
make get-password
```

## Pasos manuales

### 1. Crear namespace e instalar ArgoCD

```bash
# Crear namespace
kubectl apply -f ../shared/argocd-namespace.yaml

# Instalar ArgoCD (manifiestos oficiales)
# Se usa --server-side porque los CRDs de ArgoCD 3.x exceden el limite de kubectl client-side
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Espera a que todos los pods esten listos:

```bash
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s
```

Verifica la instalacion:

```bash
kubectl get pods -n argocd
```

Deberias ver ~7 pods corriendo:
```
argocd-application-controller-0       1/1     Running
argocd-applicationset-controller-...  1/1     Running
argocd-dex-server-...                 1/1     Running
argocd-notifications-controller-...   1/1     Running
argocd-redis-...                      1/1     Running
argocd-repo-server-...                1/1     Running
argocd-server-...                     1/1     Running
```

### 2. Exponer ArgoCD

Cambiamos el servicio a NodePort para acceder desde el navegador:

```bash
kubectl patch svc argocd-server -n argocd -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {"port": 80, "targetPort": 8080, "nodePort": 30002, "name": "http"},
      {"port": 443, "targetPort": 8080, "nodePort": 30003, "name": "https"}
    ]
  }
}'
```

ArgoCD ahora es accesible en: **https://localhost:30003**

### 3. Obtener credenciales

```bash
# Usuario: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

Abre https://localhost:30003 en tu navegador (acepta el certificado auto-firmado) e ingresa con las credenciales.

### 4. Crear una Application (ejemplo)

Una **Application** en ArgoCD conecta un repositorio Git con un namespace del cluster.

Revisa `../shared/argocd-app-example.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ejemplo-nodejs-service
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/TU-ORG/mi-servicio.git
    targetRevision: main
    path: k8s                    # Directorio con los manifiestos
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true                # Eliminar recursos huerfanos
      selfHeal: true             # Corregir drift automaticamente
```

Para aplicarla:

```bash
# Edita primero el repoURL con tu repositorio
kubectl apply -f ../shared/argocd-app-example.yaml
```

Tambien puedes crear Applications desde la UI de ArgoCD:
1. Click en **+ NEW APP**
2. Llena los campos (repo URL, path, destination)
3. Click en **CREATE**

### 5. Integrar ArgoCD con Backstage

Para ver el estado de ArgoCD directamente en Backstage:

**a) Aplicar la configuracion:**

```bash
kubectl apply -f backstage-argocd-config.yaml
```

**b) Agregar anotaciones a las entidades del catalogo:**

```yaml
# catalog-info.yaml de tu servicio
metadata:
  annotations:
    argocd/app-name: ejemplo-nodejs-service   # Nombre de la App en ArgoCD
    backstage.io/kubernetes-id: mi-servicio   # Para el plugin de K8s
```

**c) Verificar en Backstage:**

1. Abre Backstage (http://localhost:30000)
2. Ve a un componente con la anotacion `argocd/app-name`
3. Deberia aparecer un tab o widget de ArgoCD mostrando:
   - Sync status (Synced/OutOfSync)
   - Health status (Healthy/Degraded)
   - Ultimo sync
   - Historial de deployments

### 6. Instalar ArgoCD CLI (opcional)

```bash
# macOS
brew install argocd

# Linux / WSL2
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/
```

Comandos utiles:

```bash
# Login
argocd login localhost:30003 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --insecure

# Listar apps
argocd app list

# Ver detalles de una app
argocd app get ejemplo-nodejs-service

# Sincronizar manualmente
argocd app sync ejemplo-nodejs-service

# Ver diferencias entre Git y cluster
argocd app diff ejemplo-nodejs-service
```

## Flujo completo: Golden Path + ArgoCD

Con todo configurado, el flujo completo es:

1. Developer usa el **Golden Path** en Backstage para crear un servicio
2. El template genera un repo con codigo + manifiestos K8s + `catalog-info.yaml`
3. Se crea una **Application en ArgoCD** apuntando al repo
4. Developer hace cambios y pushea a Git
5. **ArgoCD detecta el cambio** y sincroniza automaticamente
6. En **Backstage** se puede ver:
   - Estado de los pods (plugin K8s)
   - Estado de ArgoCD sync (plugin ArgoCD)
   - Todo desde un solo lugar

## Troubleshooting

### No puedo acceder a la UI de ArgoCD
```bash
# Verificar que el servicio es NodePort
kubectl get svc argocd-server -n argocd

# Alternativa: port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Acceder a https://localhost:8080
```

### La Application queda en "OutOfSync" constantemente
- Verifica que el path del repo es correcto
- Verifica que los manifiestos son validos: `kubectl apply --dry-run=client -f k8s/`
- Revisa los eventos: click en la app en la UI > Events

### ArgoCD no puede acceder al repo Git
- Si es un repo privado, necesitas configurar credenciales:
  ```bash
  argocd repo add https://github.com/tu-org/tu-repo.git \
    --username tu-usuario --password tu-token
  ```

### Pods de ArgoCD en CrashLoopBackOff
Generalmente es por falta de recursos. Verifica:
```bash
kubectl describe pod -n argocd -l app.kubernetes.io/name=argocd-server
```

## Limpiar

```bash
make clean
# O manualmente:
kubectl delete namespace argocd
```

---

**Paso anterior:** [05 - GitOps Conceptos](../05-gitops-conceptos/) | **Siguiente paso:** [07 - Seguridad SSO y Politicas](../07-seguridad-sso-politicas/)
