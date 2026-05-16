# Workshop: Backstage Golden Paths - De Zero a Plataforma de Desarrollo

Workshop interactivo para construir una **Plataforma Interna de Desarrollo (IDP)** usando [Backstage](https://backstage.io), Golden Paths, GitOps y seguridad empresarial. Soporta dos modos de ejecucion: **Kubernetes** y **Local**.

## Que vas a construir

```
┌─────────────────────────────────────────────────────────────────┐
│                        BACKSTAGE (IDP)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │  Software     │  │  Kubernetes  │  │  ArgoCD               │  │
│  │  Templates    │  │  Plugin      │  │  Plugin               │  │
│  │  (Golden      │  │  (Visualizar │  │  (Estado de           │  │
│  │   Paths)      │  │   Workloads) │  │   Deployments)        │  │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────┘  │
│         │                 │                       │              │
│  ┌──────┴─────────────────┴───────────────────────┴───────────┐  │
│  │              Auth (GitHub OAuth + Keycloak)                 │  │
│  │              RBAC + Politicas de Acceso                     │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
         │                 │                       │
         ▼                 ▼                       ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐
│  Git Repos   │  │  Kubernetes  │  │  ArgoCD                  │
│  (Scaffolded │  │  Cluster     │  │  (Continuous Delivery)   │
│   Projects)  │  │  (Kind)      │  │                          │
└──────────────┘  └──────────────┘  └──────────────────────────┘
```

## Modos de ejecucion

| Modo | Backstage corre en | Comando | Acceso |
|------|--------------------|---------|--------|
| **Kubernetes** (default) | Pod en el cluster Kind | `make all` o `make all MODE=k8s` | http://localhost:30000 |
| **Local** | Tu maquina con `yarn start` | `make all MODE=local` | http://localhost:3000 |

Ambos modos usan el cluster Kind para workloads (K8s plugin, ArgoCD).

## Prerequisitos

### Ambos modos
- **Sistema operativo:** macOS, Linux o Windows (via WSL2)
- **Docker** funcionando (OrbStack/Docker Desktop/Docker Engine)
- **Kind**, **kubectl**, **Helm**, **tmux** instalados
- **Cuenta de GitHub** (para el paso de autenticacion)
- ~8 GB de RAM disponible
- ~10 GB de espacio en disco

### Setup por sistema operativo

| SO | Guia de instalacion | Runtime de contenedores |
|----|---------------------|------------------------|
| **macOS** | Homebrew: `brew install kind kubectl helm tmux` | [OrbStack](https://orbstack.dev) (recomendado) o Docker Desktop |
| **Linux** | [docs/setup-linux.md](docs/setup-linux.md) | Docker Engine (nativo) |
| **Windows** | [docs/setup-windows.md](docs/setup-windows.md) | Docker Desktop + WSL2 |

> **Windows:** Todos los comandos del workshop se ejecutan dentro de **WSL2**, no en PowerShell/CMD. Ver la [guia de Windows](docs/setup-windows.md) para detalles.

### Modo local (adicional)
- **Node.js 20+** (ver guia de tu SO para instalacion)
- **Docker** (para PostgreSQL y Keycloak via docker-compose)

## Pasos del Workshop

| Paso | Tema | Descripcion | Duracion estimada |
|------|------|-------------|-------------------|
| [01](01-kubernetes-local/) | Kubernetes Local | Setup de Docker + Kind (macOS/Linux/Windows) | 15 min |
| [02](02-deploy-backstage/) | Deploy Backstage | Desplegar Backstage con PostgreSQL en K8s | 20 min |
| [03](03-golden-paths/) | Golden Paths | Crear Software Templates para scaffolding | 25 min |
| [04](04-backstage-kubernetes-plugin/) | Plugin Kubernetes | Visualizar workloads de K8s desde Backstage | 20 min |
| [05](05-gitops-conceptos/) | GitOps Conceptos | Principios GitOps y flujo CI/CD | 15 min (lectura) |
| [06](06-deploy-gitops/) | Deploy GitOps | Instalar ArgoCD e integrar con Backstage | 25 min |
| [07](07-seguridad-sso-politicas/) | Seguridad | SSO (GitHub + Keycloak), RBAC y politicas | 30 min |
| [08](08-rbac-multi-capa/) | RBAC Multi-Capa | Del login al deploy: control de acceso end-to-end | 25 min |

## Inicio rapido

### Modo Kubernetes (default)

```bash
# Ejecutar todo el workshop
make all

# O paso a paso
make step-01    # Kubernetes local
make step-02    # Deploy Backstage en K8s
make step-03    # Golden Paths
make step-04    # Kubernetes Plugin
make step-05    # GitOps conceptos (solo lectura)
make step-06    # Deploy ArgoCD
make step-07    # Seguridad SSO
make step-08    # RBAC Multi-Capa
```

### Modo Local

```bash
# Ejecutar todo el workshop en modo local
make all MODE=local
# o
make all-local

# Paso a paso
make step-01                # Kubernetes (igual en ambos modos)
make step-02 MODE=local     # PostgreSQL + Backstage local
make step-03 MODE=local     # Templates via paths locales
make step-04 MODE=local     # K8s plugin via kubeconfig
make step-05                # GitOps conceptos (solo lectura)
make step-06 MODE=local     # ArgoCD + plugin via NodePort
make step-07 MODE=local     # Keycloak via Docker Compose
make step-08 MODE=local     # RBAC Multi-Capa
```

### Comandos comunes

```bash
# Verificar todos los pasos
make verify-all

# Verificar un paso especifico
make verify step=02

# Ver estado de todos los componentes
make status

# Limpiar todo
make clean
# o para modo local:
make clean MODE=local
```

## Como usar este workshop

### Modo interactivo (recomendado)
1. Navega a cada carpeta en orden (`01-kubernetes-local/`, `02-deploy-backstage/`, etc.)
2. Lee el `README.md` de cada paso para entender los conceptos
3. Ejecuta los comandos manualmente o usa `make all` dentro de cada carpeta

### Modo automatico
1. Ejecuta `make all` desde la raiz del proyecto
2. Revisa los READMEs despues para entender que se hizo

## Arquitectura del Workshop

Cada paso sigue la misma estructura:

```
XX-nombre-del-paso/
├── README.md       # Explicacion conceptual + pasos manuales
├── Makefile        # Automatizacion (make all, make verify, make clean)
└── [recursos/]     # YAMLs, configs, templates segun el paso
```

## Troubleshooting

Si algo falla en cualquier paso:

1. Verifica un paso especifico: `make verify step=02`
2. Verifica todos los pasos: `make verify-all`
3. Revisa el estado general: `make status`
4. Si todo falla: `make clean` y empieza de nuevo

## Licencia

MIT
