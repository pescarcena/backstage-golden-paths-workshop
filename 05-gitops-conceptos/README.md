# Paso 05: GitOps - Conceptos y Flujo CI/CD con Backstage

Este paso es **solo lectura**. Aqui entendemos los principios de GitOps y como se integra con Backstage para crear un flujo completo de CI/CD.

## Que es GitOps?

**GitOps** es una practica operacional que usa Git como **unica fuente de verdad** para la infraestructura y las aplicaciones. Todo cambio al sistema pasa por Git.

### Los 4 principios de GitOps (segun OpenGitOps)

1. **Declarativo**: El sistema deseado se describe de forma declarativa (YAML, HCL, etc.)
2. **Versionado e inmutable**: El estado deseado se almacena en Git, con historial completo
3. **Automatico**: Los cambios aprobados se aplican automaticamente al sistema
4. **Reconciliacion continua**: Un agente verifica que el estado actual coincida con el deseado

### GitOps vs CI/CD tradicional

```
CI/CD TRADICIONAL (Push)
========================
Developer → Git Push → CI Build → CI Deploy → Cluster
                                      ↑
                            CI tiene credenciales
                            del cluster (riesgo)

GITOPS (Pull)
=============
Developer → Git Push → CI Build → Actualiza Git (manifiestos)
                                        │
                                        ▼
            Cluster ← Pull ← ArgoCD observa Git
                               ↑
                     ArgoCD ya tiene acceso
                     al cluster (es local)
```

| Aspecto | CI/CD Tradicional | GitOps |
|---------|-------------------|--------|
| Quien despliega | CI server (Jenkins, GitHub Actions) | Agente en el cluster (ArgoCD) |
| Fuente de verdad | Pipeline + scripts | Git |
| Acceso al cluster | CI necesita credenciales | Solo el agente tiene acceso |
| Rollback | Re-ejecutar pipeline anterior | `git revert` |
| Auditoria | Logs del CI | Git history |
| Drift detection | No hay | Reconciliacion continua |

## Flujo completo: Backstage + GitOps

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUJO COMPLETO                                │
│                                                                         │
│  1. CREAR          2. DESARROLLAR      3. CI            4. CD (GitOps) │
│  ┌──────────┐     ┌──────────┐       ┌──────────┐     ┌──────────┐    │
│  │ Backstage│     │Developer │       │ GitHub   │     │  ArgoCD  │    │
│  │ Template │────▶│ Git Push │──────▶│ Actions  │────▶│  Sync    │    │
│  │(Golden   │     │          │       │          │     │          │    │
│  │ Path)    │     │          │       │ Build    │     │ Deploy   │    │
│  └──────────┘     └──────────┘       │ Test     │     │ Monitor  │    │
│       │                               │ Image    │     │          │    │
│       │                               └────┬─────┘     └────┬─────┘    │
│       │                                    │                 │          │
│       │           5. OBSERVAR              │                 │          │
│       │           ┌──────────┐             │                 │          │
│       └──────────▶│ Backstage│◀────────────┘                 │          │
│                   │ Catalogo │◀───────────────────────────────┘          │
│                   │ K8s Tab  │                                          │
│                   │ ArgoCD   │                                          │
│                   └──────────┘                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Desglose del flujo:

#### 1. Crear (Backstage Golden Path)
- Developer selecciona un template en Backstage
- Backstage genera el repositorio con:
  - Codigo fuente (skeleton)
  - Dockerfile
  - Manifiestos de Kubernetes
  - Pipeline CI (GitHub Actions)
  - `catalog-info.yaml` (registro en Backstage)

#### 2. Desarrollar
- Developer hace cambios al codigo
- Push a una rama, crea un Pull Request
- Code review y merge a `main`

#### 3. CI (Continuous Integration)
- GitHub Actions (o tu CI preferido) se activa con el push
- Ejecuta: lint, tests, build de imagen Docker
- Publica la imagen al registro (Docker Hub, GHCR, ECR)
- Actualiza los manifiestos de K8s con la nueva version de la imagen

#### 4. CD (Continuous Delivery - GitOps)
- ArgoCD detecta el cambio en los manifiestos de Git
- Sincroniza automaticamente con el cluster
- Aplica los nuevos manifiestos (rolling update)
- Verifica que el deployment este saludable

#### 5. Observar (Backstage)
- En Backstage puedes ver:
  - Estado del deployment (plugin Kubernetes)
  - Estado de ArgoCD sync (plugin ArgoCD)
  - Historial de deployments
  - Logs y metricas

## Estructura de repositorios en GitOps

Hay dos patrones comunes:

### Patron 1: Monorepo (codigo + manifiestos juntos)

```
mi-servicio/
├── src/                    # Codigo fuente
├── Dockerfile
├── .github/workflows/      # CI pipeline
│   └── ci.yaml
├── k8s/                    # Manifiestos de Kubernetes
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── catalog-info.yaml       # Backstage
```

**Pros**: Simple, todo en un lugar
**Contras**: CI se dispara con cambios a manifiestos, menos separacion de concerns

### Patron 2: Repos separados (App + GitOps)

```
mi-servicio/                    mi-servicio-gitops/
├── src/                        ├── base/
├── Dockerfile                  │   ├── deployment.yaml
├── .github/workflows/          │   ├── service.yaml
│   └── ci.yaml                 │   └── kustomization.yaml
└── catalog-info.yaml           └── overlays/
                                    ├── dev/
                                    ├── staging/
                                    └── production/
```

**Pros**: Separacion clara, CI no afecta CD, multiples ambientes
**Contras**: Mas repos que mantener

### Cual elegir?

Para este workshop usamos el **Patron 1** (monorepo) por simplicidad. En produccion, el Patron 2 es mas comun.

## ArgoCD vs FluxCD

Para este workshop usamos **ArgoCD**, pero es bueno conocer ambas opciones:

| Caracteristica | ArgoCD | FluxCD |
|---------------|--------|--------|
| UI Web | Si (muy completa) | No (solo CLI) |
| Sincronizacion | Pull-based | Pull-based |
| Multi-cluster | Si | Si |
| Helm support | Si | Si |
| Kustomize | Si | Si |
| RBAC | Si (integrado) | Via Kubernetes RBAC |
| Plugin Backstage | Oficial | Comunidad |
| Proyecto CNCF | Graduated | Graduated |
| Curva de aprendizaje | Media | Baja |

### Por que ArgoCD para este workshop?

1. **UI Web**: Permite visualizar el estado de los deployments facilmente
2. **Plugin oficial de Backstage**: Integracion directa con el catalogo
3. **Popularidad**: Es el mas adoptado en la industria
4. **Multi-tenancy**: Mejor soporte para multiples equipos

## El rol de Backstage en GitOps

Backstage NO es una herramienta de GitOps. Su rol es ser el **centro de control** que une todo:

```
┌─────────────────────────────────────────┐
│              BACKSTAGE                   │
│                                          │
│  "Desde aqui puedo ver todo"             │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │ Crear    │  │ Ver      │  │ Ver    │ │
│  │ nuevos   │  │ estado   │  │ estado │ │
│  │ servicios│  │ de K8s   │  │ de CD  │ │
│  │          │  │          │  │(ArgoCD)│ │
│  │ Templates│  │ K8s      │  │ ArgoCD │ │
│  │ (Paso 03)│  │ Plugin   │  │ Plugin │ │
│  │          │  │ (Paso 04)│  │(Paso 06)│ │
│  └──────────┘  └──────────┘  └────────┘ │
└─────────────────────────────────────────┘
```

## Resumen

- **GitOps** = Git como fuente de verdad + reconciliacion automatica
- **ArgoCD** = Agente GitOps que sincroniza Git con Kubernetes
- **Backstage** = Portal que unifica creacion, observacion y gestion
- **Golden Path + GitOps** = Developer crea un servicio y automaticamente tiene CI/CD configurado

En el siguiente paso, vamos a desplegar ArgoCD en nuestro cluster y conectarlo con Backstage.

---

**Paso anterior:** [04 - Backstage Kubernetes Plugin](../04-backstage-kubernetes-plugin/) | **Siguiente paso:** [06 - Deploy GitOps (ArgoCD)](../06-deploy-gitops/)
