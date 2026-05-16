# =============================================================================
# Paso 03: Golden Paths - Software Templates
# =============================================================================

.PHONY: all create-configmap update-app-config patch-deployment wait-backstage verify clean help

TEMPLATE_DIR := ../shared/templates/nodejs-service
SKELETON_DIR := ../shared/templates/backstage-skeleton
K8S_DIR := .

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: create-configmap update-app-config patch-deployment wait-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 03 completado! Golden Paths configurados.$(NC)"
	@echo ""
	@echo "Accede a Backstage y ve a $(YELLOW)Create$(NC) para ver los templates registrados"
	@echo "  $(YELLOW)http://localhost:30000/create$(NC)"

## Crear ConfigMap con los archivos del template
create-configmap:
	@echo "$(BOLD)Creando ConfigMap con archivos de los templates...$(NC)"
	@kubectl create configmap backstage-templates -n backstage \
		--from-file=nodejs-template.yaml=$(TEMPLATE_DIR)/template.yaml \
		--from-file=nodejs-package.json=$(TEMPLATE_DIR)/skeleton/package.json \
		--from-file=nodejs-Dockerfile=$(TEMPLATE_DIR)/skeleton/Dockerfile \
		--from-file=nodejs-catalog-info.yaml=$(TEMPLATE_DIR)/skeleton/catalog-info.yaml \
		--from-file=nodejs-src-index.js=$(TEMPLATE_DIR)/skeleton/src/index.js \
		--from-file=skeleton-template.yaml=$(SKELETON_DIR)/template.yaml \
		--from-file=skeleton-catalog-info.yaml=$(SKELETON_DIR)/skeleton/catalog-info.yaml \
		--from-file=skeleton-Dockerfile=$(SKELETON_DIR)/skeleton/Dockerfile \
		--from-file=skeleton-src-index.html=$(SKELETON_DIR)/skeleton/src/index.html \
		--from-file=skeleton-chart.yaml=$(SKELETON_DIR)/skeleton/charts/app/Chart.yaml \
		--from-file=skeleton-values.yaml=$(SKELETON_DIR)/skeleton/charts/app/values.yaml \
		--from-file=skeleton-deployment.yaml=$(SKELETON_DIR)/skeleton/charts/app/templates/deployment.yaml \
		--from-file=skeleton-service.yaml=$(SKELETON_DIR)/skeleton/charts/app/templates/service.yaml \
		--from-file=skeleton-argocd-app.yaml=$(SKELETON_DIR)/skeleton/argocd/application.yaml \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)ConfigMap backstage-templates creado$(NC)"

## Actualizar app-config con la ubicacion del template
update-app-config:
	@echo "$(BOLD)Actualizando app-config con ubicacion del template...$(NC)"
	@kubectl apply -f $(K8S_DIR)/backstage-app-config.yaml
	@echo "$(GREEN)app-config actualizado$(NC)"

## Parchear el Deployment para montar los templates
patch-deployment:
	@echo "$(BOLD)Parcheando Deployment de Backstage...$(NC)"
	@kubectl patch deployment backstage -n backstage \
		--type=strategic \
		--patch-file $(K8S_DIR)/deployment-patch.yaml
	@echo "$(GREEN)Deployment parcheado$(NC)"

## Esperar a que Backstage reinicie
wait-backstage:
	@echo "$(YELLOW)Esperando a que Backstage reinicie (max 5 min)...$(NC)"
	@kubectl rollout status deployment/backstage -n backstage --timeout=300s
	@echo "$(GREEN)Backstage listo$(NC)"

## Verificar que el template esta disponible
verify:
	@echo ""
	@echo "$(BOLD)Verificando Golden Paths...$(NC)"
	@echo ""
	@echo "--- ConfigMap backstage-templates ---"
	@kubectl get configmap backstage-templates -n backstage -o jsonpath='{.metadata.name}' && echo " $(GREEN)✓$(NC)" || echo " $(RED)✗$(NC)"
	@echo ""
	@echo "--- Templates registrados en Backstage ---"
	@attempt=1; \
	FOUND_NODEJS=0; \
	FOUND_SKELETON=0; \
	while [ $$attempt -le 5 ]; do \
		RESULT=$$(curl -s http://localhost:30000/api/catalog/entities?filter=kind=template 2>/dev/null); \
		if echo "$$RESULT" | grep -q "nodejs-service" 2>/dev/null; then \
			echo "$(GREEN)✓ Template 'nodejs-service' registrado en el catalogo$(NC)"; \
			FOUND_NODEJS=1; \
		fi; \
		if echo "$$RESULT" | grep -q "golden-path-traditional" 2>/dev/null; then \
			echo "$(GREEN)✓ Template 'golden-path-traditional' registrado en el catalogo$(NC)"; \
			FOUND_SKELETON=1; \
		fi; \
		if [ $$FOUND_NODEJS -eq 1 ] && [ $$FOUND_SKELETON -eq 1 ]; then \
			break; \
		fi; \
		if [ $$attempt -eq 5 ]; then \
			echo "$(YELLOW)⏳ Algunos templates aun no visibles en el catalogo (puede tardar ~30s)$(NC)"; \
			echo "  Verifica manualmente en: http://localhost:30000/create"; \
		fi; \
		sleep 10; \
		attempt=$$((attempt + 1)); \
	done

## Limpiar recursos del paso 03
clean:
	@echo "$(RED)Eliminando recursos del paso 03...$(NC)"
	@kubectl delete configmap backstage-templates -n backstage --ignore-not-found=true
	@echo "$(YELLOW)Nota: Para restaurar Backstage sin templates, re-aplica el paso 02$(NC)"
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 03: Golden Paths$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                Crear ConfigMap, parchear deployment y verificar"
	@echo "  $(YELLOW)create-configmap$(NC)   Crear ConfigMap con archivos del template"
	@echo "  $(YELLOW)update-app-config$(NC)  Actualizar app-config con ubicacion del template"
	@echo "  $(YELLOW)patch-deployment$(NC)   Parchear Deployment para montar templates"
	@echo "  $(YELLOW)verify$(NC)             Verificar que el template esta registrado"
	@echo "  $(YELLOW)clean$(NC)              Eliminar recursos del paso 03"

.DEFAULT_GOAL := help
