# =============================================================================
# Paso 02: Desplegar Backstage - Modo Local
# =============================================================================

.PHONY: all start-postgres create-app configure start-backstage status verify clean help

BACKSTAGE_APP_DIR := backstage-app

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: start-postgres create-app configure
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 02 (local) completado!$(NC)"
	@echo ""
	@echo "$(BOLD)Para iniciar Backstage:$(NC)"
	@echo "  cd $(BACKSTAGE_APP_DIR) && yarn start"
	@echo ""
	@echo "$(BOLD)Acceso:$(NC)"
	@echo "  Frontend: $(YELLOW)http://localhost:3000$(NC)"
	@echo "  Backend:  $(YELLOW)http://localhost:7007$(NC)"

## Iniciar PostgreSQL via Docker Compose
start-postgres:
	@echo "$(BOLD)Iniciando PostgreSQL...$(NC)"
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@docker compose up -d postgres
	@echo "$(YELLOW)Esperando a que PostgreSQL este listo...$(NC)"
	@until docker compose exec postgres pg_isready -U backstage -q 2>/dev/null; do sleep 2; done
	@echo "$(GREEN)PostgreSQL listo en localhost:5432$(NC)"

## Crear la app de Backstage con create-app
create-app:
	@if [ -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(YELLOW)Backstage app ya existe en $(BACKSTAGE_APP_DIR). Saltando.$(NC)"; \
	else \
		echo "$(BOLD)Creando app de Backstage...$(NC)"; \
		echo "$(YELLOW)Esto puede tardar unos minutos...$(NC)"; \
		npx @backstage/create-app@0.8.2 --path $(BACKSTAGE_APP_DIR) --skip-install; \
		cd $(BACKSTAGE_APP_DIR) && yarn install; \
		echo "$(GREEN)App de Backstage creada$(NC)"; \
	fi

## Copiar configuracion local al proyecto
configure:
	@echo "$(BOLD)Configurando Backstage para modo local...$(NC)"
	@cp app-config.local.yaml $(BACKSTAGE_APP_DIR)/app-config.local.yaml
	@echo "$(GREEN)Configuracion copiada$(NC)"

## Iniciar Backstage (foreground) con todos los configs de los steps
start-backstage:
	@echo "$(BOLD)Iniciando Backstage...$(NC)"
	@ABS_APP_DIR=$$(cd $(BACKSTAGE_APP_DIR) && pwd); \
	CONFIGS="--config $$ABS_APP_DIR/app-config.yaml --config $$ABS_APP_DIR/app-config.local.yaml"; \
	for f in $(BACKSTAGE_APP_DIR)/app-config.*.yaml; do \
		case "$$f" in \
			*/app-config.local.yaml) ;; \
			*/app-config.production.yaml) ;; \
			*) CONFIGS="$$CONFIGS --config $$ABS_APP_DIR/$$(basename $$f)" ;; \
		esac; \
	done; \
	echo "$(YELLOW)Configs: $$CONFIGS$(NC)"; \
	echo "$(YELLOW)Presiona Ctrl+C para detener$(NC)"; \
	cd $(BACKSTAGE_APP_DIR) && BROWSER=none POSTGRES_USER=backstage POSTGRES_PASSWORD=backstage123 yarn start $$CONFIGS

## Ver estado
status:
	@echo "$(BOLD)Estado (modo local):$(NC)"
	@echo ""
	@echo "--- PostgreSQL ---"
	@docker compose ps 2>/dev/null || echo "  Docker Compose no esta corriendo"
	@echo ""
	@echo "--- Backstage App ---"
	@if [ -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "  $(GREEN)✓$(NC) App existe en $(BACKSTAGE_APP_DIR)"; \
	else \
		echo "  $(RED)✗$(NC) App no creada. Ejecuta: make create-app"; \
	fi

## Verificar que todo funciona
verify:
	@echo ""
	@echo "$(BOLD)Verificando Backstage (local)...$(NC)"
	@echo ""
	@docker compose exec postgres pg_isready -U backstage -q 2>/dev/null && \
		echo "$(GREEN)✓ PostgreSQL esta listo$(NC)" || \
		echo "$(RED)✗ PostgreSQL no esta corriendo$(NC)"
	@if [ -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(GREEN)✓ App de Backstage existe$(NC)"; \
	else \
		echo "$(RED)✗ App no creada$(NC)"; \
	fi
	@curl -s -o /dev/null -w "" http://localhost:7007/healthcheck 2>/dev/null && \
		echo "$(GREEN)✓ Backstage esta respondiendo$(NC)" || \
		echo "$(YELLOW)⏳ Backstage no esta respondiendo (ejecuta: make start-backstage)$(NC)"

## Limpiar todo
clean:
	@echo "$(RED)Eliminando recursos locales...$(NC)"
	@docker compose down -v 2>/dev/null || true
	@if [ -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(YELLOW)Nota: $(BACKSTAGE_APP_DIR)/ no se elimina automaticamente.$(NC)"; \
		echo "  Para eliminarlo: rm -rf $(BACKSTAGE_APP_DIR)"; \
	fi
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 02: Deploy Backstage (Local)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)               Preparar todo (postgres + create-app + configure)"
	@echo "  $(YELLOW)start-postgres$(NC)    Iniciar PostgreSQL via Docker Compose"
	@echo "  $(YELLOW)create-app$(NC)        Crear app Backstage con npx"
	@echo "  $(YELLOW)configure$(NC)         Copiar configuracion local"
	@echo "  $(YELLOW)start-backstage$(NC)   Iniciar Backstage (yarn start)"
	@echo "  $(YELLOW)status$(NC)            Ver estado"
	@echo "  $(YELLOW)verify$(NC)            Verificar que todo funciona"
	@echo "  $(YELLOW)clean$(NC)             Limpiar recursos"

.DEFAULT_GOAL := help
