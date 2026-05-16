# Paso 03: Golden Paths - Software Templates

En este paso vamos a entender que son los **Golden Paths** y como implementarlos en Backstage usando **Software Templates**.

## Conceptos clave

### Que son los Golden Paths?

Los Golden Paths (tambien llamados "Paved Roads" o "Caminos Dorados") son **caminos pre-definidos y optimizados** que una organizacion ofrece a sus desarrolladores para crear y operar software.

> "Un Golden Path no es una restriccion, es una autopista. Puedes tomar caminos secundarios, pero la autopista te lleva mas rapido y con menos friccion."

### El problema que resuelven

Sin Golden Paths:
```
Desarrollador nuevo → "Como creo un servicio?"
                    → Busca en Confluence (desactualizado)
                    → Copia otro proyecto (con malas practicas)
                    → Configura CI/CD manualmente (inconsistente)
                    → 2 semanas despues: primer deploy
```

Con Golden Paths:
```
Desarrollador nuevo → Abre Backstage
                    → Selecciona template "Servicio Node.js"
                    → Llena formulario (nombre, equipo, repo)
                    → 5 minutos despues: repo creado, CI/CD configurado, registrado en catalogo
```

### Golden Paths en Backstage: Software Templates

Backstage implementa Golden Paths mediante **Software Templates** (Scaffolder):

```
┌─────────────────────────────────────────────────────────────┐
│                    SOFTWARE TEMPLATE                         │
│                                                              │
│  1. PARAMETROS         2. SKELETON           3. ACCIONES    │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐ │
│  │ Formulario   │     │ Archivos     │     │ Crear repo   │ │
│  │ que llena    │────▶│ template     │────▶│ en GitHub    │ │
│  │ el usuario   │     │ con valores  │     │ Registrar en │ │
│  │              │     │ inyectados   │     │ catalogo     │ │
│  └──────────────┘     └──────────────┘     └──────────────┘ │
│                                                              │
│  nombre: mi-api        package.json         github.com/...  │
│  owner: team-a         Dockerfile           catalog entry   │
│  port: 3000            src/index.js         CI/CD pipeline  │
└─────────────────────────────────────────────────────────────┘
```

## Estructura del template

Nuestro template de ejemplo crea un **servicio Node.js con Express**:

```
templates/nodejs-service/
├── template.yaml          # Definicion del template (parametros + pasos)
└── skeleton/              # Archivos que se generan
    ├── catalog-info.yaml  # Registro en Backstage
    ├── Dockerfile         # Multi-stage build
    ├── package.json       # Dependencias Node.js
    └── src/
        └── index.js       # Aplicacion Express
```

### template.yaml explicado

El archivo `template.yaml` tiene tres secciones principales:

#### 1. Parametros (el formulario)

```yaml
parameters:
  - title: Informacion del servicio
    properties:
      name:                    # Nombre del servicio
        type: string
        pattern: "^[a-z0-9-]+$"  # Solo minusculas, numeros y guiones
      owner:                   # Equipo propietario
        ui:field: OwnerPicker  # Widget especial de Backstage
      port:                    # Puerto HTTP
        type: number
        default: 3000
```

#### 2. Skeleton (los archivos template)

Los archivos en `skeleton/` usan la sintaxis `${{ values.nombre }}` para inyectar valores:

```javascript
// src/index.js
const PORT = process.env.PORT || ${{ values.port }};
app.listen(PORT, () => {
  console.log(`Servicio ${{ values.name }} escuchando en puerto ${PORT}`);
});
```

#### 3. Acciones (los pasos de creacion)

```yaml
steps:
  - id: fetch-skeleton       # Genera archivos desde el skeleton
    action: fetch:template
  - id: publish               # Publica en GitHub
    action: publish:github
  - id: register              # Registra en el catalogo de Backstage
    action: catalog:register
```

## Prerequisitos

- Paso 01 completado (cluster Kind)
- Paso 02 completado (Backstage corriendo)

## Modo automatico

```bash
make all
```

Esto ejecuta los siguientes pasos:
1. Crea un ConfigMap con los archivos del template
2. Actualiza el app-config de Backstage con la ubicacion del template
3. Parchea el Deployment para montar los templates dentro del contenedor
4. Espera a que Backstage reinicie
5. Verifica que el template este registrado

## Pasos manuales

### 1. Explorar el template

Revisa los archivos del template:

```bash
# Ver la estructura
tree templates/nodejs-service/

# Ver la definicion del template
cat templates/nodejs-service/template.yaml

# Ver el skeleton
cat templates/nodejs-service/skeleton/src/index.js
```

### 2. Crear el ConfigMap con los archivos del template

Los archivos del template necesitan estar disponibles dentro del contenedor de Backstage. Creamos un ConfigMap con todos los archivos:

```bash
kubectl create configmap backstage-templates -n backstage \
  --from-file=template.yaml=templates/nodejs-service/template.yaml \
  --from-file=skeleton-package.json=templates/nodejs-service/skeleton/package.json \
  --from-file=skeleton-Dockerfile=templates/nodejs-service/skeleton/Dockerfile \
  --from-file=skeleton-catalog-info.yaml=templates/nodejs-service/skeleton/catalog-info.yaml \
  --from-file=skeleton-src-index.js=templates/nodejs-service/skeleton/src/index.js \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 3. Actualizar el app-config

Aplicamos el ConfigMap actualizado que agrega la referencia al template en `catalog.locations`:

```bash
kubectl apply -f k8s/backstage-app-config.yaml
```

### 4. Parchear el Deployment

El patch agrega un **init container** que arma la estructura de directorios del template y un volumen para montarlos en Backstage:

```bash
kubectl patch deployment backstage -n backstage \
  --type=strategic \
  --patch-file k8s/deployment-patch.yaml
```

Backstage se reiniciara automaticamente. Espera a que este listo:

```bash
kubectl rollout status deployment/backstage -n backstage --timeout=300s
```

### 3. Usar el template

1. En Backstage (http://localhost:30000), ve a **Create**
2. Selecciona el template **"Servicio Node.js"**
3. Llena el formulario:
   - **Nombre**: `mi-primer-servicio`
   - **Equipo**: (selecciona uno)
   - **Puerto**: `3000`
   - **Version Node.js**: `20`
   - **Repositorio**: tu organizacion en GitHub
4. Click en **Create**

Backstage ejecutara los pasos automaticamente:
- Genera los archivos desde el skeleton
- Crea el repositorio en GitHub
- Registra el servicio en el catalogo

### 4. Verificar el resultado

Despues de crear el servicio:

- **En GitHub**: Deberias ver un nuevo repositorio con todos los archivos
- **En Backstage**: El servicio aparece en el catalogo (Home > Catalog)

## Como crear tus propios Golden Paths

### Paso a paso para un nuevo template:

1. **Crea el skeleton** con los archivos de tu proyecto
2. **Parametriza** los valores variables con `${{ values.nombre }}`
3. **Define el template.yaml** con los parametros y acciones
4. **Registra** en Backstage

### Acciones disponibles en Backstage

| Accion | Descripcion |
|--------|-------------|
| `fetch:template` | Genera archivos desde un skeleton |
| `fetch:plain` | Copia archivos sin procesar |
| `publish:github` | Crea repo en GitHub |
| `publish:gitlab` | Crea repo en GitLab |
| `catalog:register` | Registra en el catalogo |
| `catalog:write` | Escribe catalog-info.yaml |
| `github:actions:dispatch` | Dispara un GitHub Action |

### Buenas practicas para Golden Paths

1. **Opinionado pero flexible**: Define valores por defecto pero permite personalizacion
2. **Incluye todo**: CI/CD, Dockerfile, tests, documentacion, monitoreo
3. **Mantelo actualizado**: Un Golden Path desactualizado es peor que no tener uno
4. **Itera**: Empieza simple, agrega complejidad segun la necesidad
5. **Documenta**: Cada template debe explicar que hace y por que

## Troubleshooting

### El template no aparece en Backstage
- Verifica que el `template.yaml` tiene la API correcta: `scaffolder.backstage.io/v1beta3`
- Verifica que esta registrado en `catalog.locations`
- Reinicia Backstage: `kubectl rollout restart deployment/backstage -n backstage`

### Error al crear desde el template
Revisa los logs de Backstage:
```bash
kubectl logs -n backstage -l app=backstage -f
```

### El skeleton no genera bien los archivos
Verifica que usas la sintaxis correcta: `${{ values.nombreDelParametro }}`

---

**Paso anterior:** [02 - Deploy Backstage](../02-deploy-backstage/) | **Siguiente paso:** [04 - Backstage Kubernetes Plugin](../04-backstage-kubernetes-plugin/)
