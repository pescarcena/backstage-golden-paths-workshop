# Setup del Workshop en Linux

Guia de prerequisitos e instalacion para distribuciones Linux (Ubuntu/Debian, Fedora/RHEL, Arch).

## Requisitos del sistema

- ~8 GB de RAM disponible
- ~10 GB de espacio en disco
- Cuenta de GitHub (para el paso de autenticacion)
- Acceso a internet

## 1. Docker Engine

En Linux **no necesitas OrbStack** (que es exclusivo de macOS). Docker corre nativamente.

### Ubuntu / Debian

```bash
# Agregar repositorio oficial de Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Permitir usar Docker sin sudo
sudo usermod -aG docker $USER
newgrp docker
```

### Fedora / RHEL

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```

### Arch Linux

```bash
sudo pacman -S docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```

### Verificar Docker

```bash
docker version
docker compose version
```

## 2. Kind (Kubernetes IN Docker)

```bash
# Opcion A: Descarga directa (recomendado)
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Opcion B: Con Go instalado
go install sigs.k8s.io/kind@v0.29.0
```

```bash
kind version
```

## 3. kubectl

```bash
# Descarga directa
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# O via snap
sudo snap install kubectl --classic
```

```bash
kubectl version --client
```

## 4. Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

```bash
helm version
```

## 5. cloud-provider-kind

```bash
# Con Go instalado
go install sigs.k8s.io/cloud-provider-kind@latest

# O descarga directa desde releases
# https://github.com/kubernetes-sigs/cloud-provider-kind/releases
```

> **Nota:** En Linux, `cloud-provider-kind` puede requerir `sudo` dependiendo de la configuracion de Docker.

## 6. tmux (opcional, para servicios en background)

```bash
# Ubuntu/Debian
sudo apt-get install -y tmux

# Fedora
sudo dnf install -y tmux

# Arch
sudo pacman -S tmux
```

## 7. Node.js 20+ (solo modo local)

```bash
# Opcion recomendada: nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# O via package manager
# Ubuntu/Debian (NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Fedora
sudo dnf install -y nodejs
```

```bash
node --version   # Debe ser 20+
npm --version
```

## Diferencias con macOS

| Aspecto | macOS | Linux |
|---------|-------|-------|
| Runtime de contenedores | OrbStack (recomendado) | Docker Engine nativo |
| Package manager | Homebrew | apt / dnf / pacman |
| `sudo` para cloud-provider-kind | Siempre requerido | Depende de config Docker |
| Puerto en uso (`lsof`) | `lsof -i :30000` | `ss -tlnp \| grep 30000` |
| Rendimiento Docker | Virtualizado (VM ligera) | Nativo (mejor rendimiento) |

## Verificar todo

```bash
docker version
kind version
kubectl version --client
helm version
```

Si todo responde correctamente, continua con el [Paso 01: Kubernetes Local](../01-kubernetes-local/).

## Troubleshooting

### "permission denied" al usar Docker
Asegurate de haber agregado tu usuario al grupo `docker`:
```bash
sudo usermod -aG docker $USER
# Cierra sesion y vuelve a abrir, o ejecuta:
newgrp docker
```

### Kind falla al crear el cluster
Verifica que Docker esta corriendo:
```bash
sudo systemctl status docker
```

### Puerto ya en uso
```bash
ss -tlnp | grep 30000
# Para matar el proceso:
sudo kill $(ss -tlnp | grep 30000 | awk '{print $NF}' | grep -o '[0-9]*')
```
