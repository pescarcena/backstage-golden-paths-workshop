# Setup del Workshop en Windows (via WSL2)

Este workshop usa herramientas del ecosistema Linux/Unix (Make, bash, Kind, kubectl). En Windows, la ruta recomendada es **WSL2** (Windows Subsystem for Linux), que es el estandar de la industria para desarrollo con Kubernetes en Windows.

> **Importante:** Todos los comandos del workshop (`make`, `kind`, `kubectl`, `helm`, `yarn`) se ejecutan **dentro de WSL2**, no en PowerShell ni CMD.

## Requisitos del sistema

- Windows 10 version 2004+ o Windows 11
- ~8 GB de RAM disponible
- ~10 GB de espacio en disco
- Virtualizacion habilitada en BIOS (VT-x / AMD-V)
- Cuenta de GitHub (para el paso de autenticacion)

## 1. Instalar WSL2

Abre **PowerShell como Administrador** y ejecuta:

```powershell
wsl --install
```

Esto instala WSL2 con Ubuntu por defecto. Reinicia cuando se solicite.

Despues del reinicio, abre **Ubuntu** desde el menu de inicio y crea tu usuario Linux.

### Verificar WSL2

```powershell
# En PowerShell
wsl --version
wsl -l -v
# La columna VERSION debe mostrar "2"
```

> **Nota:** Si ya tienes WSL1, actualiza a WSL2:
> ```powershell
> wsl --set-default-version 2
> wsl --set-version Ubuntu 2
> ```

## 2. Instalar Docker Desktop

1. Descarga [Docker Desktop para Windows](https://www.docker.com/products/docker-desktop/)
2. Durante la instalacion, marca **"Use WSL 2 based engine"**
3. En Docker Desktop > Settings > Resources > WSL Integration:
   - Activa **"Enable integration with my default WSL distro"**
   - Activa la integracion con tu distro Ubuntu

### Verificar Docker (dentro de WSL2)

```bash
# Abre Ubuntu/WSL2 y ejecuta:
docker version
docker compose version
```

> **Alternativa sin Docker Desktop:** Puedes instalar Docker Engine directamente dentro de WSL2 siguiendo la [guia de Linux](./setup-linux.md#1-docker-engine). Esto evita la licencia de Docker Desktop.

## 3. Instalar herramientas dentro de WSL2

Desde aqui, **todos los comandos se ejecutan dentro de la terminal WSL2 (Ubuntu)**.

### Make y utilidades basicas

```bash
sudo apt-get update
sudo apt-get install -y make curl git
```

### Kind

```bash
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### cloud-provider-kind

```bash
# Requiere Go instalado
sudo apt-get install -y golang-go
go install sigs.k8s.io/cloud-provider-kind@latest

# Agregar Go bin al PATH (si no esta)
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

### tmux (opcional, para servicios en background)

```bash
sudo apt-get install -y tmux
```

### Node.js 20+ (solo modo local)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

## 4. Clonar el repositorio dentro de WSL2

Para mejor rendimiento, clona el repositorio en el filesystem de WSL2 (no en `/mnt/c/`):

```bash
# BIEN - filesystem nativo de WSL2 (rapido)
cd ~
git clone <url-del-repo> goldenpaths
cd goldenpaths

# MAL - filesystem de Windows montado (lento)
# cd /mnt/c/Users/tu-usuario/goldenpaths
```

> **Importante:** El rendimiento de Docker y Kind es significativamente mejor cuando los archivos estan en el filesystem nativo de WSL2 (`~/`, `/home/`), no en `/mnt/c/`.

## 5. Verificar todo

```bash
docker version
kind version
kubectl version --client
helm version
make --version
node --version   # Solo si vas a usar modo local
```

Si todo responde correctamente, continua con el [Paso 01: Kubernetes Local](../01-kubernetes-local/).

## Acceso a servicios desde el navegador Windows

Los puertos expuestos dentro de WSL2 son accesibles desde Windows automaticamente:

| Servicio | URL (desde tu navegador Windows) |
|----------|----------------------------------|
| Backstage (K8s) | http://localhost:30000 |
| Backstage (local) | http://localhost:3000 |
| ArgoCD | http://localhost:30002 |
| Keycloak | http://localhost:30004 |

> Si los puertos no son accesibles, verifica que WSL2 tiene "localhost forwarding" habilitado (es el default en versiones recientes).

## Diferencias con macOS

| Aspecto | macOS | Windows (WSL2) |
|---------|-------|----------------|
| Runtime | OrbStack | Docker Desktop + WSL2 |
| Terminal | Terminal.app / iTerm2 | Windows Terminal + Ubuntu |
| Package manager | Homebrew | apt (dentro de WSL2) |
| Filesystem | Nativo | Usar filesystem WSL2, no `/mnt/c/` |
| Puerto en uso | `lsof -i :30000` | `ss -tlnp \| grep 30000` |
| Editor | Cualquiera | VS Code con extension "WSL" |

## Tips para Windows

### VS Code + WSL2
Instala la extension [WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) en VS Code. Luego desde WSL2:
```bash
code .   # Abre VS Code conectado a WSL2
```

### Windows Terminal
Usa [Windows Terminal](https://aka.ms/terminal) para una mejor experiencia. Permite multiples tabs con diferentes shells (PowerShell, Ubuntu/WSL2, CMD).

### Memoria de WSL2
Si WSL2 consume mucha RAM, crea `%UserProfile%\.wslconfig`:
```ini
[wsl2]
memory=8GB
swap=4GB
```
Luego reinicia WSL2: `wsl --shutdown`

## Troubleshooting

### "Cannot connect to the Docker daemon" en WSL2
Verifica que Docker Desktop esta corriendo y que la integracion WSL2 esta habilitada:
- Docker Desktop > Settings > Resources > WSL Integration

### Kind falla con errores de red
Docker Desktop debe estar usando el backend WSL2:
- Docker Desktop > Settings > General > "Use the WSL 2 based engine" debe estar activado

### Los puertos no son accesibles desde Windows
```powershell
# En PowerShell, verifica que WSL2 esta escuchando
netstat -ano | findstr 30000
```

Si no funciona, reinicia WSL2:
```powershell
wsl --shutdown
```

### Rendimiento lento
Asegurate de trabajar en el filesystem nativo de WSL2:
```bash
# Verificar donde estas
pwd
# Debe mostrar /home/tu-usuario/... NO /mnt/c/...
```
