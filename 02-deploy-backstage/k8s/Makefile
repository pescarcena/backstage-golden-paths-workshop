# =============================================================================
# Paso 02: Desplegar Backstage en Kubernetes
# =============================================================================

.PHONY: all deploy-postgres wait-postgres deploy-backstage port-forward status verify clean help

K8S_DIR := manifests

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: deploy-postgres wait-postgres deploy-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 02 completado! Backstage desplegado.$(NC)"
	@echo ""
	@echo "Accede a Backstage:"
	@echo "  $(YELLOW)Via NodePort:$(NC)  http://localhost:30000"
	@echo "  $(YELLOW)Via Ingress:$(NC)   http://backstage.local (requiere entrada en /etc/hosts)"
	@echo "  $(YELLOW)Via port-forward:$(NC) make port-forward -> http://localhost:7007"

## Desplegar PostgreSQL
deploy-postgres:
	@echo "$(BOLD)Desplegando PostgreSQL...$(NC)"
	@kubectl apply -f $(K8S_DIR)/namespace.yaml
	@kubectl apply -f $(K8S_DIR)/postgres-deployment.yaml
	@kubectl apply -f $(K8S_DIR)/postgres-service.yaml
	@echo "$(GREEN)PostgreSQL desplegado$(NC)"

## Esperar a que PostgreSQL este listo
wait-postgres:
	@echo "$(YELLOW)Esperando a que PostgreSQL este listo...$(NC)"
	@kubectl wait --namespace backstage \
		--for=condition=ready pod \
		--selector=app=postgres \
		--timeout=120s
	@echo "$(GREEN)PostgreSQL listo$(NC)"

## Desplegar Backstage
deploy-backstage:
	@echo "$(BOLD)Desplegando Backstage...$(NC)"
	@kubectl apply -f $(K8S_DIR)/backstage-deployment.yaml
	@kubectl apply -f $(K8S_DIR)/backstage-service.yaml
	@echo "$(GREEN)Backstage desplegado$(NC)"
	@echo "$(YELLOW)Esperando a que Backstage este listo (max 5 min)...$(NC)"
	@attempt=1; \
	while [ $$attempt -le 5 ]; do \
		echo "$(YELLOW)  Intento $$attempt/5...$(NC)"; \
		if kubectl wait --namespace backstage \
			--for=condition=ready pod \
			--selector=app=backstage \
			--timeout=60s 2>/dev/null; then \
			echo "$(GREEN)Backstage listo$(NC)"; \
			break; \
		fi; \
		if [ $$attempt -eq 5 ]; then \
			echo "$(RED)Backstage no arranco tras 5 intentos$(NC)"; \
			echo "  Revisa los logs: kubectl logs -n backstage -l app=backstage"; \
			exit 1; \
		fi; \
		attempt=$$((attempt + 1)); \
	done

## Abrir port-forward a Backstage (localhost:7007)
port-forward:
	@echo "$(BOLD)Abriendo port-forward a Backstage en http://localhost:7007$(NC)"
	@echo "$(YELLOW)Presiona Ctrl+C para detener$(NC)"
	@kubectl port-forward -n backstage svc/backstage 7007:7007

## Ver estado de los pods
status:
	@echo "$(BOLD)Estado de Backstage:$(NC)"
	@echo ""
	@echo "--- Pods ---"
	@kubectl get pods -n backstage -o wide
	@echo ""
	@echo "--- Servicios ---"
	@kubectl get svc -n backstage
	@echo ""
	@echo "--- HTTPRoute (Gateway API) ---"
	@kubectl get httproute -n backstage 2>/dev/null || echo "  Sin HTTPRoute configurado"

## Verificar que Backstage esta funcionando
verify:
	@echo ""
	@echo "$(BOLD)Verificando Backstage...$(NC)"
	@echo ""
	@echo "--- Pods ---"
	@kubectl get pods -n backstage
	@echo ""
	@BACKSTAGE_READY=$$(kubectl get pods -n backstage -l app=backstage -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null); \
	POSTGRES_READY=$$(kubectl get pods -n backstage -l app=postgres -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null); \
	if [ "$$POSTGRES_READY" = "True" ]; then \
		echo "$(GREEN)✓ PostgreSQL esta listo$(NC)"; \
	else \
		echo "$(RED)✗ PostgreSQL no esta listo$(NC)"; \
	fi; \
	if [ "$$BACKSTAGE_READY" = "True" ]; then \
		echo "$(GREEN)✓ Backstage esta listo$(NC)"; \
	else \
		echo "$(YELLOW)⏳ Backstage aun iniciando...$(NC)"; \
		echo "  Revisa los logs: kubectl logs -n backstage -l app=backstage -f"; \
	fi

## Limpiar todos los recursos de Backstage
clean:
	@echo "$(RED)Eliminando Backstage y PostgreSQL...$(NC)"
	@kubectl delete namespace backstage --ignore-not-found=true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 02: Deploy Backstage$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)               Desplegar todo (postgres + backstage + verify)"
	@echo "  $(YELLOW)deploy-postgres$(NC)   Desplegar PostgreSQL"
	@echo "  $(YELLOW)deploy-backstage$(NC)  Desplegar Backstage"
	@echo "  $(YELLOW)port-forward$(NC)      Abrir port-forward (localhost:7007)"
	@echo "  $(YELLOW)status$(NC)            Ver estado de los pods"
	@echo "  $(YELLOW)verify$(NC)            Verificar que todo funciona"
	@echo "  $(YELLOW)clean$(NC)             Eliminar todos los recursos"

.DEFAULT_GOAL := help
