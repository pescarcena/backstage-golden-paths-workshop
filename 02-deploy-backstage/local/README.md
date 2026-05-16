# Paso 02: Desplegar Backstage - Modo Local

En este modo, Backstage corre localmente en tu maquina usando `yarn start`, con PostgreSQL en Docker.

## Prerequisitos

- Paso 01 completado (cluster Kind funcionando)
- **Node.js 20+** (`node --version`)
- **Docker** corriendo (para PostgreSQL)
- **tmux** instalado

## Modo automatico

```bash
# Preparar todo
make all

# Iniciar Backstage (en otra terminal)
make start-backstage
```

## Pasos manuales

### 1. Iniciar PostgreSQL

```bash
# Crear .env desde el ejemplo
cp .env.example .env

# Iniciar PostgreSQL
docker compose up -d
```

### 2. Crear la app de Backstage

```bash
npx @backstage/create-app@0.8.2 --path backstage-app --skip-install
cd backstage-app && yarn install
```

### 3. Configurar Backstage

```bash
cp app-config.local.yaml backstage-app/app-config.local.yaml
```

### 4. Iniciar Backstage

```bash
cd backstage-app
POSTGRES_USER=backstage POSTGRES_PASSWORD=backstage123 yarn start
```

Backstage estara disponible en:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:7007

## Diferencias con modo Kubernetes

| Aspecto | Local | Kubernetes |
|---------|-------|------------|
| Backstage | `yarn start` en tu maquina | Pod en el cluster |
| PostgreSQL | Docker Compose (localhost:5432) | Deployment en K8s |
| Puerto frontend | 3000 | 30000 (NodePort) |
| Puerto backend | 7007 | 7007 (interno) |
| Hot reload | Si (cambios inmediatos) | No (requiere rebuild) |
| Plugins | Editables directamente | Requieren imagen custom |

## Troubleshooting

### "ECONNREFUSED" al conectar a PostgreSQL
Verifica que Docker Compose esta corriendo:
```bash
docker compose ps
docker compose logs postgres
```

### Error de version de Node.js
Backstage requiere Node.js 20+:
```bash
node --version
# Si es menor a 20, actualiza:
# macOS:        brew install node@20
# Linux/WSL2:   nvm install 20 (ver docs/setup-linux.md)
```

### Puerto 5432 ya en uso
Otro PostgreSQL esta corriendo. Detenlo o cambia el puerto en `docker-compose.yaml`.

## Limpiar

```bash
make clean
# Para eliminar la app tambien:
rm -rf backstage-app
```
