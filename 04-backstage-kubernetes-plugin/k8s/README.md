# Paso 04: Backstage Kubernetes Plugin

En este paso vamos a configurar el **plugin de Kubernetes** en Backstage para visualizar los workloads que corren en nuestro cluster directamente desde el catalogo.

## Conceptos clave

### Para que sirve el plugin de Kubernetes?

El plugin permite ver desde Backstage:

- **Pods**: Estado, logs, reinicios
- **Deployments**: Replicas, rollout status
- **Services**: Endpoints, puertos
- **Ingress**: Reglas de ruteo
- **HPA**: Metricas de auto-escalado

```
┌────────────────────────────────────────────────────────┐
│                  BACKSTAGE UI                           │
│                                                         │
│  Servicio: mi-api                                       │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Tab: KUBERNETES                                 │    │
│  │                                                  │    │
│  │  Cluster: backstage-workshop                     │    │
│  │  ┌─────────────────────────────────────────┐     │    │
│  │  │ Deployment: mi-api         2/2 Ready    │     │    │
│  │  │ ├── Pod: mi-api-abc123    Running ✓     │     │    │
│  │  │ └── Pod: mi-api-def456    Running ✓     │     │    │
│  │  │                                         │     │    │
│  │  │ Service: mi-api            ClusterIP    │     │    │
│  │  │ Ingress: mi-api            /api → :3000 │     │    │
│  │  └─────────────────────────────────────────┘     │    │
│  └─────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
                          │
                          │  API calls
                          ▼
                   ┌──────────────┐
                   │  Kubernetes  │
                   │   API Server │
                   └──────────────┘
```

### Como funciona la conexion

1. **Backstage** usa un **ServiceAccount** para autenticarse con la API de Kubernetes
2. El ServiceAccount necesita permisos **RBAC** para leer recursos
3. Las entidades del catalogo usan **anotaciones** para indicar que recursos de K8s les pertenecen

```
catalog-info.yaml                  Kubernetes
┌────────────────────┐             ┌────────────────────┐
│ annotations:        │            │ labels:             │
│   backstage.io/     │───busca───▶│   backstage.io/    │
│   kubernetes-id:    │            │   kubernetes-id:    │
│   mi-servicio       │            │   mi-servicio       │
└────────────────────┘             └────────────────────┘
```

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

## Modo automatico

```bash
make all
```

## Pasos manuales

### 1. Aplicar permisos RBAC

Backstage necesita permisos para leer recursos de Kubernetes. Aplicamos un ClusterRole y ClusterRoleBinding:

```bash
kubectl apply -f k8s-rbac.yaml
```

Esto otorga al ServiceAccount `backstage` permisos de lectura sobre:
- Pods, Services, ConfigMaps, Namespaces
- Deployments, ReplicaSets, StatefulSets, DaemonSets
- Jobs, CronJobs
- Ingresses
- HorizontalPodAutoscalers

Verifica que los permisos funcionan:

```bash
# Probar como el ServiceAccount de Backstage
kubectl auth can-i list pods --as=system:serviceaccount:backstage:backstage
# Deberia responder: yes

kubectl auth can-i list deployments --as=system:serviceaccount:backstage:backstage
# Deberia responder: yes

# Verificar que NO puede crear/eliminar (solo lectura)
kubectl auth can-i delete pods --as=system:serviceaccount:backstage:backstage
# Deberia responder: no
```

### 2. Configurar el plugin en Backstage

La configuracion del plugin esta en `app-config.k8s-plugin.yaml`:

```yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'        # Busca por anotaciones del catalogo
  clusterLocatorMethods:
    - type: 'config'           # Clusters definidos en config
      clusters:
        - name: backstage-workshop
          url: https://kubernetes.default.svc  # URL interna del cluster
          authProvider: 'serviceAccount'         # Usa el SA de Backstage
          skipTLSVerify: true                    # OK para desarrollo
```

Aplicar la configuracion:

```bash
# Crear ConfigMap con la config del plugin
kubectl create configmap backstage-k8s-config \
  --from-file=app-config.k8s-plugin.yaml \
  -n backstage \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Reiniciar Backstage

```bash
kubectl rollout restart deployment/backstage -n backstage
kubectl rollout status deployment/backstage -n backstage --timeout=180s
```

### 4. Agregar anotaciones a tus servicios

Para que un servicio del catalogo muestre informacion de Kubernetes, necesita la anotacion `backstage.io/kubernetes-id`:

```yaml
# catalog-info.yaml del servicio
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: mi-servicio
  annotations:
    backstage.io/kubernetes-id: mi-servicio
```

Y los recursos de Kubernetes deben tener el label correspondiente:

```yaml
# deployment.yaml del servicio
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    backstage.io/kubernetes-id: mi-servicio
```

Hay tres formas de hacer el match:

| Metodo | Anotacion | Busca |
|--------|----------|-------|
| kubernetes-id | `backstage.io/kubernetes-id: nombre` | Label `backstage.io/kubernetes-id=nombre` |
| namespace | `backstage.io/kubernetes-namespace: ns` | Todos los recursos en el namespace |
| label-selector | `backstage.io/kubernetes-label-selector: app=nombre` | Label personalizado |

### 5. Verificar en la UI

1. Abre Backstage (http://localhost:30000)
2. Ve a un componente del catalogo que tenga la anotacion
3. Busca el tab **"Kubernetes"** en la pagina del componente
4. Deberias ver los pods, deployments y servicios asociados

## Ejemplo completo

Revisa `../shared/catalog-info-example.yaml` para ver un ejemplo de entidad con todas las anotaciones posibles.

## Troubleshooting

### El tab de Kubernetes no aparece
- Verifica que la imagen de Backstage incluye el plugin (`@backstage/plugin-kubernetes`)
- Verifica que la configuracion de `kubernetes` esta en el app-config
- Revisa los logs: `kubectl logs -n backstage -l app=backstage -f`

### "Could not fetch Kubernetes objects"
- Verifica RBAC: `kubectl auth can-i list pods --as=system:serviceaccount:backstage:backstage`
- Verifica que el ServiceAccount existe: `kubectl get sa backstage -n backstage`

### No muestra nada para un servicio
- Verifica la anotacion `backstage.io/kubernetes-id` en el catalog-info.yaml
- Verifica el label `backstage.io/kubernetes-id` en el Deployment de K8s
- Los valores deben coincidir exactamente

---

**Paso anterior:** [03 - Golden Paths](../03-golden-paths/) | **Siguiente paso:** [05 - GitOps Conceptos](../05-gitops-conceptos/)
