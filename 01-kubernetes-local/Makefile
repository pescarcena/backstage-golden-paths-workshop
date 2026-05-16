# =============================================================================
# Paso 01: Kubernetes Local con OrbStack + Kind
# =============================================================================

.PHONY: all check-deps install-deps create-cluster install-gateway verify destroy help

MODE ?= k8s
CLUSTER_NAME := backstage-workshop
KIND_CONFIG  := kind-config.yaml
TMUX_SESSION := goldenpaths

# Detectar sistema operativo
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    HOST_OS := macos
    PKG_INSTALL := brew install
    PKG_INSTALL_CASK := brew install --cask
else ifeq ($(UNAME_S),Linux)
    HOST_OS := linux
    # Detectar distro
    ifneq ($(wildcard /etc/debian_version),)
        PKG_INSTALL := sudo apt-get install -y
    else ifneq ($(wildcard /etc/fedora-release),)
        PKG_INSTALL := sudo dnf install -y
    else ifneq ($(wildcard /etc/arch-release),)
        PKG_INSTALL := sudo pacman -S --noconfirm
    else
        PKG_INSTALL := echo "Instala manualmente:"
    endif
endif

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
ifeq ($(MODE),local)
all: check-deps create-cluster verify
else
all: check-deps create-cluster install-gateway verify
endif
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 01 completado! Cluster Kubernetes listo.$(NC)"

## Verificar que las dependencias estan instaladas
check-deps:
	@echo "$(BOLD)Verificando dependencias ($(HOST_OS))...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Error: Docker no esta instalado. Consulta docs/setup-$(HOST_OS).md$(NC)"; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "$(RED)Error: Docker no esta corriendo. Inicialo antes de continuar.$(NC)"; exit 1; }
	@echo "  $(GREEN)✓$(NC) Docker"
	@command -v kind >/dev/null 2>&1 || { echo "$(YELLOW)Kind no encontrado. Ejecuta: make install-deps$(NC)"; exit 1; }
	@echo "  $(GREEN)✓$(NC) Kind"
	@command -v kubectl >/dev/null 2>&1 || { echo "$(YELLOW)kubectl no encontrado. Ejecuta: make install-deps$(NC)"; exit 1; }
	@echo "  $(GREEN)✓$(NC) kubectl"
	@command -v helm >/dev/null 2>&1 || { echo "$(YELLOW)Helm no encontrado. Ejecuta: make install-deps$(NC)"; exit 1; }
	@echo "  $(GREEN)✓$(NC) Helm"
	@echo "$(GREEN)Todas las dependencias estan instaladas$(NC)"

## Instalar dependencias segun el SO
install-deps:
	@echo "$(BOLD)Instalando dependencias para $(HOST_OS)...$(NC)"
	@echo ""
ifeq ($(HOST_OS),macos)
	@echo "$(YELLOW)Nota: OrbStack es recomendado como runtime Docker en macOS$(NC)"
	@echo "       Instalar: brew install --cask orbstack$(NC)"
	@echo ""
	$(PKG_INSTALL) kind kubectl helm cloud-provider-kind
else ifeq ($(HOST_OS),linux)
	@echo "$(YELLOW)Instalando Kind...$(NC)"
	@if ! command -v kind >/dev/null 2>&1; then \
		curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-$$([ $$(uname -m) = x86_64 ] && echo amd64 || echo arm64); \
		chmod +x ./kind; \
		sudo mv ./kind /usr/local/bin/kind; \
	else echo "  Kind ya instalado"; fi
	@echo "$(YELLOW)Instalando kubectl...$(NC)"
	@if ! command -v kubectl >/dev/null 2>&1; then \
		curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
		chmod +x kubectl; \
		sudo mv kubectl /usr/local/bin/; \
	else echo "  kubectl ya instalado"; fi
	@echo "$(YELLOW)Instalando Helm...$(NC)"
	@if ! command -v helm >/dev/null 2>&1; then \
		curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; \
	else echo "  Helm ya instalado"; fi
	@echo "$(YELLOW)Para cloud-provider-kind ver: docs/setup-linux.md$(NC)"
endif
	@echo ""
	@echo "$(GREEN)Dependencias instaladas$(NC)"
	@echo "$(YELLOW)Asegurate de que Docker este corriendo antes de continuar$(NC)"

## Crear el cluster Kind
create-cluster:
	@if kind get clusters 2>/dev/null | grep -q "$(CLUSTER_NAME)"; then \
		echo "$(YELLOW)El cluster '$(CLUSTER_NAME)' ya existe. Saltando creacion.$(NC)"; \
	else \
		echo "$(BOLD)Creando cluster Kind '$(CLUSTER_NAME)'...$(NC)"; \
		kind create cluster --config $(KIND_CONFIG); \
		echo "$(GREEN)Cluster creado exitosamente$(NC)"; \
	fi

## Instalar Gateway API via cloud-provider-kind (solo MODE=k8s)
install-gateway:
	@echo "$(BOLD)Configurando Gateway API...$(NC)"
	@echo ""
	@echo "$(YELLOW)Instalando CRDs de Gateway API...$(NC)"
	@kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
	@echo ""
	@echo "$(YELLOW)Desplegando Gateway...$(NC)"
	@kubectl apply -f gateway.yaml
	@echo ""
	@echo "$(BOLD)Iniciando cloud-provider-kind...$(NC)"
	@if pgrep -f "cloud-provider-kind" >/dev/null 2>&1; then \
		echo "$(GREEN)✓ cloud-provider-kind ya esta corriendo$(NC)"; \
	elif command -v tmux >/dev/null 2>&1; then \
		if ! tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
			tmux new-session -d -s $(TMUX_SESSION) -n shell; \
		fi; \
		if ! tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^cloud-provider$$'; then \
			tmux new-window -t $(TMUX_SESSION) -n cloud-provider; \
			tmux send-keys -t $(TMUX_SESSION):cloud-provider 'sudo cloud-provider-kind --gateway-channel standard' Enter; \
		fi; \
		echo "$(GREEN)cloud-provider-kind lanzado en tmux (sesion: $(TMUX_SESSION), ventana: cloud-provider)$(NC)"; \
		echo "$(YELLOW)Si necesitas ingresar password sudo: tmux attach -t $(TMUX_SESSION):cloud-provider$(NC)"; \
	else \
		echo "$(RED)Error: tmux no esta instalado y cloud-provider-kind no esta corriendo.$(NC)"; \
		echo "$(YELLOW)Instala tmux: macOS: brew install tmux | Linux/WSL2: sudo apt-get install tmux$(NC)"; \
		exit 1; \
	fi

## Verificar que todo esta funcionando
verify:
	@echo ""
	@echo "$(BOLD)Verificando el cluster...$(NC)"
	@echo ""
	@echo "--- Informacion del cluster ---"
	@kubectl cluster-info --context kind-$(CLUSTER_NAME)
	@echo ""
	@echo "--- Nodos ---"
	@kubectl get nodes -o wide
	@echo ""
	@echo "--- Namespaces ---"
	@kubectl get namespaces
	@echo ""
ifneq ($(MODE),local)
	@echo "--- Gateway API ---"
	@kubectl get gatewayclass 2>/dev/null && echo "" || echo "  $(YELLOW)GatewayClass no encontrado (cloud-provider-kind no esta corriendo?)$(NC)"
	@kubectl get gateway -A 2>/dev/null || echo "  Sin Gateways configurados"
endif
	@echo ""
	@echo "$(GREEN)$(BOLD)✓ Cluster '$(CLUSTER_NAME)' verificado y funcionando$(NC)"

## Destruir el cluster Kind
destroy:
	@echo "$(RED)Destruyendo cluster '$(CLUSTER_NAME)'...$(NC)"
	@kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || true
	@echo "$(GREEN)Cluster eliminado$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 01: Kubernetes Local$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)              Ejecutar todo (check + create + gateway + verify)"
	@echo "  $(YELLOW)check-deps$(NC)       Verificar dependencias instaladas"
	@echo "  $(YELLOW)install-deps$(NC)     Instalar dependencias con Homebrew"
	@echo "  $(YELLOW)create-cluster$(NC)   Crear el cluster Kind"
	@echo "  $(YELLOW)install-gateway$(NC)  Instalar Gateway API + cloud-provider-kind"
	@echo "  $(YELLOW)verify$(NC)           Verificar que todo funciona"
	@echo "  $(YELLOW)destroy$(NC)          Destruir el cluster"

.DEFAULT_GOAL := help
