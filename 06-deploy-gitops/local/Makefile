# =============================================================================
# Paso 06: Deploy GitOps - ArgoCD - Modo Local
# =============================================================================

.PHONY: all check-prereqs install-argocd wait-argocd configure-argocd get-password configure-backstage verify status clean help

ARGOCD_VERSION := stable

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

BACKSTAGE_APP_DIR := ../../02-deploy-backstage/local/backstage-app

## Verificar prerequisitos
check-prereqs:
	@kubectl cluster-info --context kind-backstage-workshop >/dev/null 2>&1 || { \
		echo "$(RED)Error: Paso 01 no completado. Ejecuta primero: make step-01$(NC)"; \
		exit 1; \
	}

## Ejecutar todo el paso
all: check-prereqs install-argocd wait-argocd configure-argocd configure-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 06 (local) completado! ArgoCD desplegado.$(NC)"
	@echo ""
	@echo "$(YELLOW)Reinicia Backstage para aplicar los cambios.$(NC)"

## Instalar ArgoCD en el cluster
install-argocd:
	@echo "$(BOLD)Instalando ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-namespace.yaml
	@kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml
	@echo "$(GREEN)ArgoCD instalado$(NC)"

## Esperar a que ArgoCD este listo
wait-argocd:
	@echo "$(YELLOW)Esperando a que ArgoCD este listo (puede tardar 2-3 min)...$(NC)"
	@kubectl wait --namespace argocd \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=300s
	@echo "$(GREEN)ArgoCD listo$(NC)"

## Configurar ArgoCD: exponer via NodePort
configure-argocd:
	@echo "$(BOLD)Configurando acceso a ArgoCD...$(NC)"
	@kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30002, "name": "http"}, {"port": 443, "targetPort": 8080, "nodePort": 30003, "name": "https"}]}}'
	@echo "$(GREEN)ArgoCD expuesto en:$(NC) $(YELLOW)https://localhost:30003$(NC)"
	@echo ""
	@echo "$(BOLD)Credenciales:$(NC)"
	@echo "  Usuario: $(YELLOW)admin$(NC)"
	@printf "  Password: $(YELLOW)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo "$(NC)"

## Mostrar password de ArgoCD
get-password:
	@printf "Password: "
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

## Copiar config del plugin ArgoCD al proyecto Backstage
configure-backstage:
	@echo "$(BOLD)Configurando plugin ArgoCD para Backstage local...$(NC)"
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Backstage app no encontrada$(NC)"; \
		exit 1; \
	fi
	@cp app-config.argocd.yaml $(BACKSTAGE_APP_DIR)/app-config.argocd.yaml
	@echo "$(GREEN)Config del plugin ArgoCD copiada$(NC)"

## Ver estado
status:
	@echo "$(BOLD)Estado de ArgoCD:$(NC)"
	@echo ""
	@echo "--- Pods ---"
	@kubectl get pods -n argocd 2>/dev/null || echo "  ArgoCD no desplegado"
	@echo ""
	@echo "--- Applications ---"
	@kubectl get applications -n argocd 2>/dev/null || echo "  Sin aplicaciones"

## Verificar
verify:
	@echo ""
	@echo "$(BOLD)Verificando ArgoCD (local)...$(NC)"
	@echo ""
	@ARGOCD_READY=$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null); \
	if [ "$$ARGOCD_READY" = "True" ]; then \
		echo "$(GREEN)✓ ArgoCD Server listo$(NC)"; \
	else \
		echo "$(RED)✗ ArgoCD Server no listo$(NC)"; \
	fi
	@if [ -f "$(BACKSTAGE_APP_DIR)/app-config.argocd.yaml" ]; then \
		echo "$(GREEN)✓ Config ArgoCD copiada a Backstage$(NC)"; \
	else \
		echo "$(YELLOW)⏳ Config pendiente$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)Acceso:$(NC)"
	@echo "  ArgoCD:   $(YELLOW)https://localhost:30003$(NC)"
	@echo "  Usuario:  $(YELLOW)admin$(NC)"
	@printf "  Password: $(YELLOW)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || printf "no disponible"
	@echo "$(NC)"

## Limpiar
clean:
	@echo "$(RED)Eliminando ArgoCD...$(NC)"
	@kubectl delete namespace argocd --ignore-not-found=true
	@rm -f $(BACKSTAGE_APP_DIR)/app-config.argocd.yaml 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)ArgoCD eliminado$(NC)"

## Ayuda
help:
	@echo "$(BOLD)Paso 06: ArgoCD (Local)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                   Todo (install + config + verify)"
	@echo "  $(YELLOW)install-argocd$(NC)        Instalar ArgoCD en el cluster"
	@echo "  $(YELLOW)configure-argocd$(NC)      Configurar acceso NodePort"
	@echo "  $(YELLOW)get-password$(NC)          Mostrar password"
	@echo "  $(YELLOW)configure-backstage$(NC)   Copiar config a Backstage"
	@echo "  $(YELLOW)status$(NC)                Ver estado"
	@echo "  $(YELLOW)verify$(NC)                Verificar"
	@echo "  $(YELLOW)clean$(NC)                 Limpiar"

.DEFAULT_GOAL := help
