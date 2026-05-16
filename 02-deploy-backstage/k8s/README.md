# Paso 02: Desplegar Backstage en Kubernetes

En este paso vamos a desplegar [Backstage](https://backstage.io) en nuestro cluster de Kubernetes local. Backstage es una plataforma open-source creada por Spotify para construir portales de desarrollo internos.

## Conceptos clave

### Que es Backstage?

Backstage es un **portal de desarrollo interno (IDP)** que unifica todas las herramientas, servicios y documentacion de una organizacion en un solo lugar.

```
┌─────────────────────────────────────────────────────────────┐
│                     BACKSTAGE                                │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Catalogo    │  │  Software    │  │  TechDocs    │       │
│  │  de          │  │  Templates   │  │              │       │
│  │  Servicios   │  │  (Golden     │  │  Documentacion│      │
│  │              │  │   Paths)     │  │  como codigo │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  Plugins     │  │  Search      │  │  API         │       │
│  │  (K8s, CI/CD,│  │              │  │  Explorer    │       │
│  │   Monitoring)│  │              │  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
                          │
                    ┌─────┴─────┐
                    │ PostgreSQL │
                    │ (Base de  │
                    │  datos)   │
                    └───────────┘
```

### Arquitectura del despliegue

Nuestro despliegue consta de dos componentes:

1. **PostgreSQL**: Base de datos para almacenar el catalogo, usuarios y configuracion
2. **Backstage**: La aplicacion web (frontend + backend)

## Prerequisitos

- Paso 01 completado (cluster Kind funcionando)

## Modo automatico

```bash
# Desplegar todo
make all

# Acceder a Backstage via NodePort
# Abre http://localhost:30000 en tu navegador
```

## Pasos manuales

### 1. Crear el namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

Esto crea el namespace `backstage` donde viviran todos los recursos.

### 2. Desplegar PostgreSQL

```bash
# Desplegar el Secret, PVC y Deployment de PostgreSQL
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
```

Espera a que este listo:

```bash
kubectl wait --namespace backstage \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=120s
```

Verifica:

```bash
kubectl get pods -n backstage
```

```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-xxxxxxxxx-xxxxx    1/1     Running   0          30s
```

### 3. Desplegar Backstage

El archivo `k8s/backstage-deployment.yaml` contiene:
- **ConfigMap** con la configuracion de Backstage (`app-config.yaml`)
- **ServiceAccount** para Backstage
- **Deployment** con la imagen oficial de Backstage

```bash
kubectl apply -f k8s/backstage-deployment.yaml
kubectl apply -f k8s/backstage-service.yaml
```

Backstage tarda ~1-2 minutos en iniciar. El Makefile reintenta hasta 5 veces (1 min cada intento):

```bash
# Si ejecutas manualmente, espera con:
kubectl wait --namespace backstage \
  --for=condition=ready pod \
  --selector=app=backstage \
  --timeout=60s
```

### 4. Acceder a Backstage

Hay tres formas de acceder:

**Opcion A: Port-forward (mas simple)**

```bash
kubectl port-forward -n backstage svc/backstage 7007:7007
```

Abre http://localhost:30000

**Opcion B: NodePort**

El servicio expone Backstage en el puerto 30000:

http://localhost:30000

**Opcion C: Gateway API (requiere configuracion de DNS)**

Si completaste el paso 01 con cloud-provider-kind corriendo, hay un HTTPRoute configurado. Obtiene la IP del Gateway:

```bash
kubectl get gateway -n gateway-infra workshop-gateway -o jsonpath='{.status.addresses[0].value}'
```

Agrega esta entrada a `/etc/hosts` con esa IP:

```bash
GATEWAY_IP=$(kubectl get gateway -n gateway-infra workshop-gateway -o jsonpath='{.status.addresses[0].value}')
sudo sh -c "echo \"${GATEWAY_IP} backstage.local\" >> /etc/hosts"
```

Luego accede a http://backstage.local

### 5. Verificar el despliegue

```bash
# Ver todos los recursos
kubectl get all -n backstage

# Ver logs de Backstage
kubectl logs -n backstage -l app=backstage -f

# Ver logs de PostgreSQL
kubectl logs -n backstage -l app=postgres -f
```

## Que se creo?

| Recurso | Nombre | Descripcion |
|---------|--------|-------------|
| Namespace | `backstage` | Aislamiento de recursos |
| Secret | `postgres-secrets` | Credenciales de PostgreSQL |
| PVC | `postgres-pvc` | Almacenamiento persistente (2Gi) |
| Deployment | `postgres` | Base de datos PostgreSQL 17 |
| Service | `postgres` | Servicio interno ClusterIP |
| ConfigMap | `backstage-app-config` | Configuracion de Backstage |
| ServiceAccount | `backstage` | Identidad de Backstage en K8s |
| Deployment | `backstage` | Aplicacion Backstage |
| Service | `backstage` | Servicio NodePort (30000) |
| HTTPRoute | `backstage` | Ruta Gateway API via backstage.local |

## Entendiendo la configuracion

El archivo `app-config.yaml` (dentro del ConfigMap) es el corazon de la configuracion de Backstage:

```yaml
app:
  title: Workshop Golden Paths          # Nombre que aparece en la UI
  baseUrl: http://localhost:30000       # URL base del frontend (NodePort)

backend:
  baseUrl: http://localhost:30000       # URL base del backend
  listen:
    port: 7007                          # Puerto interno del contenedor
  auth:
    keys:
      - secret: ${BACKSTAGE_BACKEND_SECRET}  # Requerido en modo produccion

auth:
  providers:
    guest:
      dangerouslyAllowOutsideDevelopment: true  # Permitir guest fuera de dev

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location, Template]
```

> **Nota**: Se usa la imagen `ghcr.io/backstage/backstage:1.35.0` (version fija) para evitar incompatibilidades con plugins de versiones mas recientes.

En los siguientes pasos agregaremos mas configuracion (templates, plugins, auth).

## Troubleshooting

### Backstage no inicia (CrashLoopBackOff)
Revisa los logs:
```bash
kubectl logs -n backstage -l app=backstage --previous
```

Causa comun: PostgreSQL no esta listo cuando Backstage intenta conectarse. Verifica que PostgreSQL este Running primero.

### "Connection refused" al acceder a localhost:7007
El port-forward puede haberse desconectado. Ejecuta `make port-forward` de nuevo.

### PostgreSQL no tiene espacio
El PVC es de 2Gi. Para un workshop es suficiente, pero puedes editarlo en `postgres-deployment.yaml`.

## Limpiar

```bash
make clean
# O manualmente:
kubectl delete namespace backstage
```

---

**Paso anterior:** [01 - Kubernetes Local](../01-kubernetes-local/) | **Siguiente paso:** [03 - Golden Paths](../03-golden-paths/)
