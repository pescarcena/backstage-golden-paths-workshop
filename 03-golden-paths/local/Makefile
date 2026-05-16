# =============================================================================
# Paso 03: Golden Paths - Modo Local
# =============================================================================

.PHONY: all check-prereqs configure verify clean help

BACKSTAGE_APP_DIR := ../../02-deploy-backstage/local/backstage-app

# Usar Python3 para ediciones robustas de YAML (sed multilinea falla en macOS)
PYTHON := python3

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

## Ejecutar todo el paso
all: check-prereqs configure verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 03 (local) completado! Golden Paths configurados.$(NC)"
	@echo ""
	@echo "$(YELLOW)Reinicia Backstage para aplicar los cambios.$(NC)"
	@echo "Accede a $(YELLOW)http://localhost:3000/create$(NC) para ver el template."

## Copiar templates y registrarlos en app-config.yaml
configure:
	@echo "$(BOLD)Configurando templates para modo local...$(NC)"
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Backstage app no encontrada en $(BACKSTAGE_APP_DIR)$(NC)"; \
		echo "  Ejecuta primero: make -C ../../02-deploy-backstage all MODE=local"; \
		exit 1; \
	fi
	@mkdir -p $(BACKSTAGE_APP_DIR)/templates
	@cp -r ../shared/templates/nodejs-service $(BACKSTAGE_APP_DIR)/templates/
	@cp -r ../shared/templates/backstage-skeleton $(BACKSTAGE_APP_DIR)/templates/
	@cp ../shared/org.yaml $(BACKSTAGE_APP_DIR)/org.yaml
	@$(PYTHON) register-templates.py $(BACKSTAGE_APP_DIR)/app-config.yaml
	@echo "$(GREEN)Templates copiados y configurados$(NC)"

## Verificar
verify:
	@echo ""
	@echo "$(BOLD)Verificando Golden Paths (local)...$(NC)"
	@echo ""
	@if [ -f "../shared/templates/nodejs-service/template.yaml" ]; then \
		echo "$(GREEN)✓$(NC) Template Node.js disponible en: shared/templates/nodejs-service/"; \
	else \
		echo "$(RED)✗$(NC) Template Node.js no encontrado"; \
	fi
	@if [ -f "../shared/templates/backstage-skeleton/template.yaml" ]; then \
		echo "$(GREEN)✓$(NC) Template Backstage Skeleton disponible en: shared/templates/backstage-skeleton/"; \
	else \
		echo "$(RED)✗$(NC) Template Backstage Skeleton no encontrado"; \
	fi
	@if [ -d "$(BACKSTAGE_APP_DIR)/templates/nodejs-service" ] && [ -d "$(BACKSTAGE_APP_DIR)/templates/backstage-skeleton" ]; then \
		echo "$(GREEN)✓$(NC) Templates copiados al proyecto Backstage"; \
	else \
		echo "$(YELLOW)⏳$(NC) Templates pendientes (ejecuta: make configure)"; \
	fi
	@if grep -q "nodejs-service/template.yaml" $(BACKSTAGE_APP_DIR)/app-config.yaml 2>/dev/null; then \
		echo "$(GREEN)✓$(NC) Template Node.js registrado en app-config.yaml"; \
	else \
		echo "$(YELLOW)⏳$(NC) Template Node.js no registrado en app-config.yaml"; \
	fi
	@if grep -q "backstage-skeleton/template.yaml" $(BACKSTAGE_APP_DIR)/app-config.yaml 2>/dev/null; then \
		echo "$(GREEN)✓$(NC) Template Backstage Skeleton registrado en app-config.yaml"; \
	else \
		echo "$(YELLOW)⏳$(NC) Template Backstage Skeleton no registrado en app-config.yaml"; \
	fi

## Limpiar
clean:
	@echo "$(YELLOW)Eliminando configuracion de templates...$(NC)"
	@rm -rf $(BACKSTAGE_APP_DIR)/templates 2>/dev/null || true
	@rm -f $(BACKSTAGE_APP_DIR)/org.yaml 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 03: Golden Paths (Local)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)         Configurar templates y verificar"
	@echo "  $(YELLOW)configure$(NC)   Copiar config de templates a Backstage"
	@echo "  $(YELLOW)verify$(NC)      Verificar configuracion"
	@echo "  $(YELLOW)clean$(NC)       Limpiar"

.DEFAULT_GOAL := help
