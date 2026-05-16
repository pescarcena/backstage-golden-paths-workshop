# Paso 01: Kubernetes Local con Docker + Kind

En este paso vamos a configurar un cluster de Kubernetes local usando **Docker** como runtime de contenedores, **Kind** (Kubernetes IN Docker) para crear el cluster y **Gateway API** como punto de entrada de red.

## Conceptos clave

### Runtime de contenedores por SO

| SO | Runtime recomendado | Alternativa |
|----|---------------------|-------------|
| **macOS** | [OrbStack](https://orbstack.dev) (ligero, optimizado para Apple Silicon) | Docker Desktop |
| **Linux** | Docker Engine (nativo) | Podman + podman-docker |
| **Windows** | Docker Desktop + WSL2 | Docker Engine dentro de WSL2 |

> **macOS:** OrbStack consume ~50% menos RAM que Docker Desktop y arranca en segundos. Es un reemplazo directo compatible con todas las herramientas Docker.
>
> **Linux:** Docker corre nativamente, sin virtualizacion. Es la plataforma con mejor rendimiento.
>
> **Windows:** Requiere WSL2. Todos los comandos de este workshop se ejecutan dentro de WSL2. Ver [docs/setup-windows.md](../docs/setup-windows.md).

### Que es Kind?

**Kind** (Kubernetes IN Docker) crea clusters de Kubernetes usando contenedores Docker como "nodos". Cada nodo del cluster es un contenedor Docker que ejecuta los componentes de Kubernetes.

```
┌─────────────────────────────────────────────────────┐
│              Tu maquina (macOS/Linux/WSL2)            │
│  ┌─────────────────────────────────────────────┐     │
│  │                Docker Engine                 │     │
│  │  ┌──────────┐  ┌────────┐  ┌────────┐       │     │
│  │  │ control  │  │ worker │  │ worker │       │     │
│  │  │  plane   │  │   01   │  │   02   │       │     │
│  │  │(container)│ │(cont.) │  │(cont.) │       │     │
│  │  └──────────┘  └────────┘  └────────┘       │     │
│  │         Cluster: backstage-workshop          │     │
│  └─────────────────────────────────────────────┘     │
│                        │                              │
│  ┌─────────────────────┴───────────────────────┐     │
│  │         cloud-provider-kind                  │     │
│  │   (Gateway API + LoadBalancer controller)    │     │
│  └─────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────┘
```

### Gateway API vs Ingress

Este workshop usa **Gateway API** en lugar del antiguo Ingress Controller (NGINX Ingress esta en proceso de retiro). Gateway API es el estandar moderno de Kubernetes para gestionar trafico de red:

| Caracteristica | Ingress (legacy) | Gateway API |
|---------------|-------------------|-------------|
| Estado | En retiro (NGINX Ingress EOL) | Estandar activo de Kubernetes |
| Expresividad | Limitada | Completa (HTTP, TCP, TLS, gRPC) |
| Separacion de roles | No | Si (infra vs app teams) |
| Portabilidad | Depende de anotaciones del controller | Nativa, portable entre implementaciones |

**cloud-provider-kind** es el controlador nativo que implementa Gateway API para clusters Kind. Maneja automaticamente el port mapping.

## Prerequisitos

- Docker funcionando (`docker version`)
- Herramientas instaladas: `kind`, `kubectl`, `helm`, `cloud-provider-kind`, `tmux`

> **Primera vez?** Consulta la guia de instalacion de tu SO:
> - **macOS:** `brew install kind kubectl helm cloud-provider-kind tmux`
> - **Linux:** [docs/setup-linux.md](../docs/setup-linux.md)
> - **Windows:** [docs/setup-windows.md](../docs/setup-windows.md)

## Modo automatico

```bash
# Instalar dependencias (si no las tienes)
make install-deps

# Ejecutar todo el paso
make all

# IMPORTANTE: En otra terminal, ejecutar cloud-provider-kind
sudo cloud-provider-kind --gateway-channel standard

# Verificar que funciona
make verify
```

## Pasos manuales

### 1. Verificar Docker

Asegurate de que Docker esta corriendo:

```bash
docker version
```

> **macOS:** Si usas OrbStack, abrelo desde Applications. Si usas Docker Desktop, inicialo.
> **Linux:** `sudo systemctl start docker`
> **Windows (WSL2):** Inicia Docker Desktop desde Windows. Verifica dentro de WSL2.

### 2. Verificar herramientas

```bash
kind version
kubectl version --client
helm version
```

> Si alguna no esta instalada, consulta la guia de tu SO:
> - **macOS:** `brew install kind kubectl helm cloud-provider-kind tmux`
> - **Linux:** [docs/setup-linux.md](../docs/setup-linux.md)
> - **Windows:** [docs/setup-windows.md](../docs/setup-windows.md)

### 3. Crear el cluster Kind

Revisa la configuracion del cluster en `kind-config.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: backstage-workshop
nodes:
  - role: control-plane
    extraPortMappings:
      # NodePorts para acceso directo a servicios
      - containerPort: 30000
        hostPort: 30000    # Backstage
      - containerPort: 30002
        hostPort: 30002    # ArgoCD HTTP
      - containerPort: 30003
        hostPort: 30003    # ArgoCD HTTPS
      - containerPort: 30004
        hostPort: 30004    # Keycloak
  - role: worker
  - role: worker
```

Crea el cluster:

```bash
kind create cluster --config kind-config.yaml
```

Este proceso tarda ~1-2 minutos. Kind descarga la imagen del nodo, crea los contenedores y configura Kubernetes.

### 4. Verificar el cluster

```bash
# Ver informacion del cluster
kubectl cluster-info --context kind-backstage-workshop

# Ver los nodos
kubectl get nodes
```

Deberias ver 3 nodos: 1 control-plane y 2 workers, todos en estado `Ready`.

```
NAME                                STATUS   ROLES           AGE   VERSION
backstage-workshop-control-plane    Ready    control-plane   1m    v1.35.x
backstage-workshop-worker           Ready    <none>          1m    v1.35.x
backstage-workshop-worker2          Ready    <none>          1m    v1.35.x
```

### 5. Instalar Gateway API

Instalamos los CRDs de Gateway API y creamos un Gateway para el workshop:

```bash
# Instalar CRDs de Gateway API (version estandar)
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml

# Crear el Gateway del workshop
kubectl apply -f gateway.yaml
```

El archivo `gateway.yaml` crea:
- Un namespace `gateway-infra`
- Un Gateway llamado `workshop-gateway` que escucha en el puerto 80

### 6. Iniciar cloud-provider-kind

cloud-provider-kind es el controlador que implementa Gateway API y LoadBalancer para Kind. Debe correr en una terminal separada:

```bash
# En otra terminal
# macOS: requiere sudo
sudo cloud-provider-kind --gateway-channel standard

# Linux: puede requerir sudo dependiendo de config Docker
sudo cloud-provider-kind --gateway-channel standard

# Windows (WSL2): ejecutar dentro de WSL2
sudo cloud-provider-kind --gateway-channel standard
```

Verifica que el GatewayClass esta disponible:

```bash
kubectl get gatewayclass
```

Deberias ver:
```
NAME                  CONTROLLER                       ACCEPTED
cloud-provider-kind   kind.x-k8s.io/cloud-provider     True
```

Verifica el Gateway:

```bash
kubectl get gateway -n gateway-infra
```

```
NAME               CLASS                 ADDRESS        READY
workshop-gateway   cloud-provider-kind   172.18.0.x     True
```

### 7. Verificar todo

```bash
# Ver todos los pods del sistema
kubectl get pods -A

# Verificar Gateway API
kubectl get gatewayclass,gateway -A
```

## Que se creo?

- **Cluster Kind** llamado `backstage-workshop` con 3 nodos
- **Gateway API CRDs** instalados (GatewayClass, Gateway, HTTPRoute, etc.)
- **Gateway** `workshop-gateway` como punto de entrada HTTP del cluster
- **cloud-provider-kind** gestionando el networking y port mapping automatico
- **NodePorts** mapeados: 30000 (Backstage), 30002-30003 (ArgoCD), 30004 (Keycloak)

## Troubleshooting

### "Cannot connect to the Docker daemon"
- **macOS:** OrbStack/Docker Desktop no esta corriendo. Abrelo desde Applications.
- **Linux:** Docker no esta activo. Ejecuta `sudo systemctl start docker`.
- **Windows:** Docker Desktop no esta corriendo. Inicialo desde Windows.

### "Kind: command not found"
- **macOS:** `brew install kind`
- **Linux/Windows (WSL2):** Ver guia de instalacion en `docs/setup-linux.md`

### Los nodos quedan en "NotReady"
Espera 1-2 minutos. Si persiste, revisa los logs:
```bash
kubectl describe node backstage-workshop-control-plane
```

### GatewayClass no aparece
cloud-provider-kind no esta corriendo. Ejecuta en otra terminal:
```bash
sudo cloud-provider-kind --gateway-channel standard
```

### Gateway queda en "Pending" sin ADDRESS
Verifica que cloud-provider-kind esta corriendo y tiene acceso al socket de Docker:
```bash
# macOS / Linux / WSL2
pgrep -f cloud-provider-kind
```

### Puerto 30000 ya esta en uso
Otro servicio usa el puerto. Busca cual:
```bash
# macOS
lsof -i :30000

# Linux / WSL2
ss -tlnp | grep 30000

# Windows (PowerShell, fuera de WSL2)
netstat -ano | findstr 30000
```

## Limpiar

```bash
# Destruir el cluster
make destroy

# O manualmente
kind delete cluster --name backstage-workshop
```

---

**Siguiente paso:** [02 - Deploy Backstage](../02-deploy-backstage/)
