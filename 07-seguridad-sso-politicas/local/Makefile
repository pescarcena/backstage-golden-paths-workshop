# =============================================================================
# Paso 07: Seguridad SSO - Modo Local
# =============================================================================

.PHONY: all check-prereqs deploy-keycloak wait-keycloak install-plugins configure-backstage test-access status verify clean help

BACKSTAGE_APP_DIR := ../../02-deploy-backstage/local/backstage-app
BACKEND_INDEX := $(BACKSTAGE_APP_DIR)/packages/backend/src/index.ts

# Detectar OS para sed in-place (macOS usa -i '', Linux usa -i)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    SED_INPLACE := sed -i ''
else
    SED_INPLACE := sed -i
endif

# Yarn: usar el binario local del proyecto (yarn 4 via corepack)
# $(abspath) resuelve el path absoluto para que funcione tras un `cd`
BACKSTAGE_APP_ABS := $(abspath $(BACKSTAGE_APP_DIR))
YARN_RELEASE := $(firstword $(wildcard $(BACKSTAGE_APP_ABS)/.yarn/releases/*.cjs))
YARN_CMD := $(if $(YARN_RELEASE),node $(YARN_RELEASE),corepack yarn)

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
all: check-prereqs deploy-keycloak wait-keycloak install-plugins configure-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 07 (local) completado! Seguridad configurada.$(NC)"
	@echo ""
	@echo "$(BOLD)Accesos:$(NC)"
	@echo "  Keycloak:  $(YELLOW)http://localhost:8180$(NC)  (admin / admin123)"
	@echo "  Backstage: $(YELLOW)http://localhost:3000$(NC)  (login via Keycloak)"
	@echo ""
	@echo "$(BOLD)Usuarios de prueba:$(NC)"
	@echo "  admin-user / admin123  (platform-team, backstage-admin)"
	@echo "  dev-user   / dev123    (developers, backstage-user)"
	@echo ""
	@echo "$(YELLOW)Reinicia Backstage para aplicar los cambios (Ctrl+C + make start-backstage).$(NC)"

## Desplegar Keycloak via Docker Compose
deploy-keycloak:
	@echo "$(BOLD)Desplegando Keycloak...$(NC)"
	@docker compose up -d keycloak
	@echo "$(GREEN)Keycloak desplegado$(NC)"

## Esperar a que Keycloak este listo
wait-keycloak:
	@echo "$(YELLOW)Esperando a que Keycloak este listo (puede tardar 1-2 min)...$(NC)"
	@attempt=1; \
	while [ $$attempt -le 12 ]; do \
		if curl -s -o /dev/null http://localhost:8180/health/ready 2>/dev/null; then \
			echo "$(GREEN)Keycloak listo$(NC)"; \
			break; \
		fi; \
		if [ $$attempt -eq 12 ]; then \
			echo "$(RED)Keycloak no respondio tras 2 minutos$(NC)"; \
			exit 1; \
		fi; \
		sleep 10; \
		attempt=$$((attempt + 1)); \
	done
	@echo ""
	@echo "$(BOLD)Acceso a Keycloak:$(NC)"
	@echo "  URL:      $(YELLOW)http://localhost:8180$(NC)"
	@echo "  Admin:    $(YELLOW)admin$(NC)"
	@echo "  Password: $(YELLOW)admin123$(NC)"

## Instalar modulo OIDC en el proyecto Backstage
install-plugins:
	@echo "$(BOLD)Instalando modulo OIDC para Keycloak...$(NC)"
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Backstage app no encontrada$(NC)"; \
		exit 1; \
	fi
	@if grep -q "auth-backend-module-oidc-provider" $(BACKSTAGE_APP_DIR)/packages/backend/package.json 2>/dev/null; then \
		echo "$(YELLOW)Modulo OIDC ya instalado$(NC)"; \
	else \
		echo "$(YELLOW)Instalando @backstage/plugin-auth-backend-module-oidc-provider...$(NC)"; \
		cd $(BACKSTAGE_APP_DIR) && $(YARN_CMD) --cwd packages/backend add @backstage/plugin-auth-backend-module-oidc-provider; \
		echo "$(GREEN)Modulo OIDC instalado$(NC)"; \
	fi
	@if grep -q "auth-backend-module-oidc-provider" $(BACKEND_INDEX) 2>/dev/null; then \
		echo "$(YELLOW)Modulo OIDC ya registrado en backend$(NC)"; \
	else \
		echo "$(YELLOW)Registrando modulo OIDC en backend...$(NC)"; \
		perl -i -pe 'my $$p=q{@backstage/plugin-auth-backend-module-oidc-provider}; print $$_ . "backend.add(import('"'"'$$p'"'"'));\n" and next if /plugin-auth-backend-module-guest-provider/' $(BACKEND_INDEX); \
		echo "$(GREEN)Modulo OIDC registrado en packages/backend/src/index.ts$(NC)"; \
	fi

## Copiar config de auth al proyecto Backstage y deshabilitar guest
configure-backstage:
	@echo "$(BOLD)Configurando auth para Backstage local...$(NC)"
	@if [ ! -d "$(BACKSTAGE_APP_DIR)" ]; then \
		echo "$(RED)Error: Backstage app no encontrada$(NC)"; \
		exit 1; \
	fi
	@cp app-config.auth.yaml $(BACKSTAGE_APP_DIR)/app-config.auth.yaml
	@echo "$(BOLD)Deshabilitando guest provider...$(NC)"
	@if grep -q "guest:" $(BACKSTAGE_APP_DIR)/app-config.yaml 2>/dev/null; then \
		$(SED_INPLACE) '/# See.*guest.*provider/d;/guest: {}/d' $(BACKSTAGE_APP_DIR)/app-config.yaml; \
		echo "$(GREEN)Guest eliminado de app-config.yaml$(NC)"; \
	fi
	@if grep -q "dangerouslyAllowOutsideDevelopment" $(BACKSTAGE_APP_DIR)/app-config.local.yaml 2>/dev/null; then \
		perl -i -0pe 's/auth:\n  providers:\n    guest:\n.*dangerouslyAllowOutsideDevelopment.*\n/auth:\n  providers: {}\n/s' $(BACKSTAGE_APP_DIR)/app-config.local.yaml; \
		echo "$(GREEN)Guest eliminado de app-config.local.yaml$(NC)"; \
	fi
	@if grep -q "auth-backend-module-guest-provider" $(BACKEND_INDEX) 2>/dev/null; then \
		echo "$(BOLD)Eliminando modulo guest-provider de index.ts...$(NC)"; \
		$(SED_INPLACE) '/auth-backend-module-guest-provider/d' $(BACKEND_INDEX); \
		$(SED_INPLACE) '/See.*auth\/guest\/provider/d' $(BACKEND_INDEX); \
		echo "$(GREEN)Modulo guest-provider eliminado de index.ts$(NC)"; \
	fi
	@echo "$(BOLD)Instalando sign-in page OIDC en frontend...$(NC)"
	@mkdir -p $(BACKSTAGE_APP_DIR)/packages/app/src/modules/auth
	@cp ../shared/auth-module/oidcAuth.ts $(BACKSTAGE_APP_DIR)/packages/app/src/modules/auth/oidcAuth.ts
	@cp ../shared/auth-module/SignInPage.tsx $(BACKSTAGE_APP_DIR)/packages/app/src/modules/auth/SignInPage.tsx
	@cp ../shared/auth-module/index.ts $(BACKSTAGE_APP_DIR)/packages/app/src/modules/auth/index.ts
	@if ! grep -q "authModule" $(BACKSTAGE_APP_DIR)/packages/app/src/App.tsx 2>/dev/null; then \
		$(SED_INPLACE) "s|import { navModule } from './modules/nav';|import { navModule } from './modules/nav';\nimport { authModule } from './modules/auth';|" $(BACKSTAGE_APP_DIR)/packages/app/src/App.tsx; \
		$(SED_INPLACE) 's/features: \[catalogPlugin, navModule\]/features: [catalogPlugin, navModule, authModule]/' $(BACKSTAGE_APP_DIR)/packages/app/src/App.tsx; \
		echo "$(GREEN)authModule registrado en App.tsx$(NC)"; \
	else \
		echo "$(YELLOW)authModule ya registrado en App.tsx$(NC)"; \
	fi
	@# sign-in-page:app NO debe desactivarse — el authModule (OIDC) usa el mismo slot
	@# Desactivarlo suprimiria el login OIDC y los usuarios entrarian sin token (401)
	@echo "$(GREEN)Config de auth copiada$(NC)"

## Guia de pruebas de acceso
test-access:
	@echo "$(BOLD)Prueba de acceso:$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Reinicia Backstage: make start-backstage (desde el root)$(NC)"
	@echo "$(YELLOW)2. Abre: http://localhost:3000$(NC)"
	@echo "$(YELLOW)3. Login con Keycloak (OIDC):$(NC)"
	@echo "   - admin-user / admin123 -> Acceso completo (platform-team)"
	@echo "   - dev-user / dev123     -> Acceso limitado (developers)"

## Estado
status:
	@echo "$(BOLD)Estado (local):$(NC)"
	@echo ""
	@echo "--- Keycloak ---"
	@docker compose ps 2>/dev/null || echo "  No corriendo"

## Verificar
verify:
	@echo ""
	@echo "$(BOLD)Verificando seguridad (local)...$(NC)"
	@echo ""
	@curl -s -o /dev/null http://localhost:8180/health/ready 2>/dev/null && \
		echo "$(GREEN)✓ Keycloak listo$(NC)" || \
		echo "$(RED)✗ Keycloak no responde$(NC)"
	@if grep -q "auth-backend-module-oidc-provider" $(BACKSTAGE_APP_DIR)/packages/backend/package.json 2>/dev/null; then \
		echo "$(GREEN)✓ Modulo OIDC instalado$(NC)"; \
	else \
		echo "$(RED)✗ Modulo OIDC no instalado$(NC)"; \
	fi
	@if grep -q "auth-backend-module-oidc-provider" $(BACKEND_INDEX) 2>/dev/null; then \
		echo "$(GREEN)✓ Modulo OIDC registrado en backend$(NC)"; \
	else \
		echo "$(RED)✗ Modulo OIDC no registrado$(NC)"; \
	fi
	@if [ -f "$(BACKSTAGE_APP_DIR)/app-config.auth.yaml" ]; then \
		echo "$(GREEN)✓ Config de auth copiada$(NC)"; \
	else \
		echo "$(YELLOW)⏳ Config pendiente$(NC)"; \
	fi

## Limpiar
clean:
	@echo "$(RED)Eliminando Keycloak y config...$(NC)"
	@docker compose down -v 2>/dev/null || true
	@rm -f $(BACKSTAGE_APP_DIR)/app-config.auth.yaml 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Ayuda
help:
	@echo "$(BOLD)Paso 07: Seguridad SSO (Local)$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                  Todo (Keycloak + OIDC plugin + auth config + verify)"
	@echo "  $(YELLOW)deploy-keycloak$(NC)      Iniciar Keycloak via Docker Compose"
	@echo "  $(YELLOW)install-plugins$(NC)      Instalar modulo OIDC en Backstage"
	@echo "  $(YELLOW)configure-backstage$(NC)  Copiar config de auth a Backstage"
	@echo "  $(YELLOW)test-access$(NC)          Guia de pruebas"
	@echo "  $(YELLOW)status$(NC)               Ver estado"
	@echo "  $(YELLOW)verify$(NC)               Verificar"
	@echo "  $(YELLOW)clean$(NC)                Limpiar"

.DEFAULT_GOAL := help
