# =============================================================================
# Paso 06: Deploy GitOps - ArgoCD
# =============================================================================

.PHONY: all install-argocd wait-argocd configure-argocd get-password \
        integrate-backstage create-app status verify clean help

ARGOCD_VERSION := stable

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: install-argocd wait-argocd configure-argocd integrate-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 06 completado! ArgoCD desplegado e integrado con Backstage.$(NC)"

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

## Configurar ArgoCD: exponer via NodePort y mostrar credenciales
configure-argocd:
	@echo "$(BOLD)Configurando acceso a ArgoCD...$(NC)"
	@kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30002, "name": "http"}, {"port": 443, "targetPort": 8080, "nodePort": 30003, "name": "https"}]}}'
	@echo "$(GREEN)ArgoCD expuesto en:$(NC)"
	@echo "  $(YELLOW)https://localhost:30003$(NC)"
	@echo ""
	@echo "$(BOLD)Credenciales de ArgoCD:$(NC)"
	@echo "  Usuario: $(YELLOW)admin$(NC)"
	@printf "  Password: $(YELLOW)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo "$(NC)"
	@echo ""
	@echo "$(YELLOW)Nota: Guarda la password. Puedes cambiarla luego con 'argocd account update-password'$(NC)"

## Mostrar la password de ArgoCD
get-password:
	@echo "$(BOLD)Password de ArgoCD:$(NC)"
	@printf "  "
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

## Integrar ArgoCD con Backstage
integrate-backstage:
	@echo "$(BOLD)Integrando ArgoCD con Backstage...$(NC)"
	@kubectl apply -f backstage-argocd-config.yaml
	@echo ""
	@echo "$(YELLOW)Para completar la integracion:$(NC)"
	@echo "  1. La imagen de Backstage debe incluir @roadiehq/backstage-plugin-argo-cd"
	@echo "  2. Agrega la anotacion 'argocd/app-name' a las entidades del catalogo"
	@echo ""
	@echo "$(GREEN)Configuracion de ArgoCD aplicada$(NC)"

## Crear una Application de ejemplo en ArgoCD
create-app:
	@echo "$(BOLD)Creando Application de ejemplo...$(NC)"
	@echo ""
	@echo "$(YELLOW)Antes de ejecutar, edita argocd-app-example.yaml:$(NC)"
	@echo "  Cambia 'TU-ORG' por tu organizacion de GitHub"
	@echo ""
	@echo "$(YELLOW)Luego ejecuta:$(NC)"
	@echo "  kubectl apply -f argocd-app-example.yaml"

## Ver estado de ArgoCD
status:
	@echo "$(BOLD)Estado de ArgoCD:$(NC)"
	@echo ""
	@echo "--- Pods ---"
	@kubectl get pods -n argocd
	@echo ""
	@echo "--- Servicios ---"
	@kubectl get svc -n argocd
	@echo ""
	@echo "--- Applications ---"
	@kubectl get applications -n argocd 2>/dev/null || echo "  Sin aplicaciones configuradas"

## Verificar la instalacion
verify:
	@echo ""
	@echo "$(BOLD)Verificando ArgoCD...$(NC)"
	@echo ""
	@ARGOCD_READY=$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null); \
	if [ "$$ARGOCD_READY" = "True" ]; then \
		echo "$(GREEN)✓ ArgoCD Server esta listo$(NC)"; \
	else \
		echo "$(RED)✗ ArgoCD Server no esta listo$(NC)"; \
	fi
	@echo ""
	@echo "--- ArgoCD Pods ---"
	@kubectl get pods -n argocd --no-headers | while read line; do echo "  $$line"; done
	@echo ""
	@echo "$(BOLD)Acceso:$(NC)"
	@echo "  URL:      $(YELLOW)https://localhost:30003$(NC)"
	@echo "  Usuario:  $(YELLOW)admin$(NC)"
	@printf "  Password: $(YELLOW)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "no disponible"
	@echo "$(NC)"

## Limpiar ArgoCD
clean:
	@echo "$(RED)Eliminando ArgoCD...$(NC)"
	@kubectl delete namespace argocd --ignore-not-found=true
	@kubectl delete configmap backstage-argocd-config -n backstage --ignore-not-found=true 2>/dev/null || true
	@echo "$(GREEN)ArgoCD eliminado$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 06: Deploy GitOps (ArgoCD)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                   Todo (install + config + integrate + verify)"
	@echo "  $(YELLOW)install-argocd$(NC)        Instalar ArgoCD"
	@echo "  $(YELLOW)configure-argocd$(NC)      Configurar acceso y credenciales"
	@echo "  $(YELLOW)get-password$(NC)          Mostrar password de admin"
	@echo "  $(YELLOW)integrate-backstage$(NC)   Integrar con Backstage"
	@echo "  $(YELLOW)create-app$(NC)            Crear Application de ejemplo"
	@echo "  $(YELLOW)status$(NC)                Ver estado de ArgoCD"
	@echo "  $(YELLOW)verify$(NC)                Verificar instalacion"
	@echo "  $(YELLOW)clean$(NC)                 Eliminar ArgoCD"

.DEFAULT_GOAL := help
