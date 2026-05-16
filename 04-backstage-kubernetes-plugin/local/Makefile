# =============================================================================
# Paso 04: Backstage Kubernetes Plugin - Modo Local
# =============================================================================

.PHONY: all check-prereqs apply-rbac configure verify clean help

BACKSTAGE_APP_DIR := ../../02-deploy-backstage/local/backstage-app
TMUX_SESSION := goldenpaths

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Verificar prerequisitos
check-prereqs:
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Paso 02 no completado. Ejecuta primero: make step-02 MODE=local$(NC)"; \
		exit 1; \
	fi
	@kubectl cluster-info --context kind-backstage-workshop >/dev/null 2>&1 || { \
		echo "$(RED)Error: Paso 01 no completado. Ejecuta primero: make step-01$(NC)"; \
		exit 1; \
	}

## Ejecutar todo el paso
all: check-prereqs apply-rbac configure verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 04 (local) completado! Plugin de Kubernetes configurado.$(NC)"
	@echo ""
	@echo "$(YELLOW)Reinicia Backstage para aplicar los cambios.$(NC)"

## Aplicar RBAC (compartido con modo K8s)
apply-rbac:
	@echo "$(BOLD)Aplicando RBAC para Backstage...$(NC)"
	@kubectl apply -f ../shared/k8s-rbac.yaml
	@echo "$(GREEN)RBAC aplicado$(NC)"

## Copiar configuracion del plugin al proyecto Backstage
configure:
	@echo "$(BOLD)Configurando plugin de Kubernetes para modo local...$(NC)"
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Backstage app no encontrada en $(BACKSTAGE_APP_DIR)$(NC)"; \
		exit 1; \
	fi
	@cp app-config.k8s-plugin.yaml $(BACKSTAGE_APP_DIR)/app-config.k8s-plugin.yaml
	@echo "$(GREEN)Config del plugin copiada$(NC)"
	@if pgrep -f "kubectl proxy" >/dev/null 2>&1; then \
		echo "$(GREEN)✓ kubectl proxy ya esta corriendo$(NC)"; \
	elif command -v tmux >/dev/null 2>&1; then \
		if ! tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
			tmux new-session -d -s $(TMUX_SESSION) -n shell; \
		fi; \
		if ! tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^kubectl-proxy$$'; then \
			tmux new-window -t $(TMUX_SESSION) -n kubectl-proxy; \
			tmux send-keys -t $(TMUX_SESSION):kubectl-proxy 'kubectl proxy' Enter; \
		fi; \
		echo "$(GREEN)kubectl proxy lanzado en tmux (sesion: $(TMUX_SESSION), ventana: kubectl-proxy)$(NC)"; \
	else \
		echo "$(YELLOW)Nota: Ejecuta 'kubectl proxy' en otra terminal antes de iniciar Backstage.$(NC)"; \
	fi

## Verificar
verify:
	@echo ""
	@echo "$(BOLD)Verificando plugin de Kubernetes (local)...$(NC)"
	@echo ""
	@echo "--- RBAC ---"
	@kubectl get clusterrole backstage-kubernetes-reader -o name 2>/dev/null && \
		echo "$(GREEN)✓ ClusterRole creado$(NC)" || \
		echo "$(RED)✗ ClusterRole no encontrado$(NC)"
	@kubectl get clusterrolebinding backstage-kubernetes-reader -o name 2>/dev/null && \
		echo "$(GREEN)✓ ClusterRoleBinding creado$(NC)" || \
		echo "$(RED)✗ ClusterRoleBinding no encontrado$(NC)"
	@echo ""
	@echo "--- Config ---"
	@if [ -f "$(BACKSTAGE_APP_DIR)/app-config.k8s-plugin.yaml" ]; then \
		echo "$(GREEN)✓ Config del plugin copiada$(NC)"; \
	else \
		echo "$(YELLOW)⏳ Config pendiente$(NC)"; \
	fi

## Limpiar
clean:
	@echo "$(RED)Eliminando RBAC y config...$(NC)"
	@kubectl delete -f ../shared/k8s-rbac.yaml --ignore-not-found=true
	@rm -f $(BACKSTAGE_APP_DIR)/app-config.k8s-plugin.yaml 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 04: K8s Plugin (Local)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)           Todo (RBAC + config + verify)"
	@echo "  $(YELLOW)apply-rbac$(NC)    Aplicar permisos RBAC en el cluster"
	@echo "  $(YELLOW)configure$(NC)     Copiar config del plugin a Backstage"
	@echo "  $(YELLOW)verify$(NC)        Verificar configuracion"
	@echo "  $(YELLOW)clean$(NC)         Limpiar recursos"

.DEFAULT_GOAL := help
