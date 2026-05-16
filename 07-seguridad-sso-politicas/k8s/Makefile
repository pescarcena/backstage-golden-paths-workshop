# =============================================================================
# Paso 07: Seguridad - SSO y Politicas
# =============================================================================

.PHONY: all deploy-keycloak wait-keycloak configure-github-auth \
        configure-keycloak-auth apply-permissions restart-backstage \
        build-backstage-image \
        test-access status verify clean help

BACKSTAGE_OIDC_IMAGE := backstage-workshop:oidc
CLUSTER_NAME := backstage-workshop

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: deploy-keycloak wait-keycloak build-backstage-image configure-keycloak-auth apply-permissions restart-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 07 completado! Seguridad configurada.$(NC)"
	@echo ""
	@echo "$(BOLD)Accesos:$(NC)"
	@echo "  Keycloak:  $(YELLOW)http://localhost:30004$(NC)  (admin / admin123)"
	@echo "  Backstage: $(YELLOW)http://localhost:30000$(NC)  (login via Keycloak o GitHub)"

## Desplegar Keycloak como IdP local
deploy-keycloak:
	@echo "$(BOLD)Desplegando Keycloak...$(NC)"
	@kubectl apply -f keycloak-deployment.yaml
	@kubectl apply -f keycloak-realm.yaml
	@echo "$(GREEN)Keycloak desplegado$(NC)"

## Esperar a que Keycloak este listo
wait-keycloak:
	@echo "$(YELLOW)Esperando a que Keycloak este listo (puede tardar 2-3 min)...$(NC)"
	@kubectl wait --namespace keycloak \
		--for=condition=ready pod \
		--selector=app=keycloak \
		--timeout=300s
	@echo "$(GREEN)Keycloak listo$(NC)"
	@echo ""
	@echo "$(BOLD)Acceso a Keycloak:$(NC)"
	@echo "  URL:      $(YELLOW)http://localhost:30004$(NC)"
	@echo "  Admin:    $(YELLOW)admin$(NC)"
	@echo "  Password: $(YELLOW)admin123$(NC)"
	@echo ""
	@echo "$(BOLD)Usuarios de prueba:$(NC)"
	@echo "  admin-user / admin123  (grupo: platform-team, rol: backstage-admin)"
	@echo "  dev-user   / dev123    (grupo: developers, rol: backstage-user)"

## Configurar GitHub OAuth en Backstage
configure-github-auth:
	@echo "$(BOLD)Configurando GitHub OAuth...$(NC)"
	@echo ""
	@echo "$(YELLOW)Pasos manuales necesarios:$(NC)"
	@echo "  1. Ve a https://github.com/settings/developers"
	@echo "  2. Click en 'New OAuth App'"
	@echo "  3. Rellena:"
	@echo "     - Application name: Backstage Workshop"
	@echo "     - Homepage URL: http://localhost:30000"
	@echo "     - Authorization callback URL: http://localhost:30000/api/auth/github/handler/frame"
	@echo "  4. Copia el Client ID y Client Secret"
	@echo "  5. Edita backstage-auth-secret.yaml con tus valores"
	@echo "  6. Ejecuta: kubectl apply -f backstage-auth-secret.yaml"
	@echo ""
	@echo "$(YELLOW)Despues de configurar, reinicia Backstage: make restart-backstage$(NC)"

## Construir imagen custom de Backstage con soporte OIDC
build-backstage-image:
	@echo "$(BOLD)Construyendo imagen custom de Backstage con OIDC...$(NC)"
	@echo "$(YELLOW)Esto puede tardar unos minutos...$(NC)"
	@docker build -f Dockerfile.backstage -t $(BACKSTAGE_OIDC_IMAGE) .
	@echo "$(GREEN)Imagen construida: $(BACKSTAGE_OIDC_IMAGE)$(NC)"
	@echo "$(BOLD)Cargando imagen en el cluster Kind...$(NC)"
	@kind load docker-image $(BACKSTAGE_OIDC_IMAGE) --name $(CLUSTER_NAME)
	@echo "$(GREEN)Imagen cargada en Kind$(NC)"
	@echo "$(BOLD)Actualizando deployment con imagen custom...$(NC)"
	@kubectl set image deployment/backstage backstage=$(BACKSTAGE_OIDC_IMAGE) -n backstage
	@kubectl patch deployment backstage -n backstage -p '{"spec":{"template":{"spec":{"containers":[{"name":"backstage","imagePullPolicy":"Never"}]}}}}'
	@echo "$(GREEN)Deployment actualizado a imagen con OIDC$(NC)"

## Configurar Keycloak (OIDC) en Backstage
configure-keycloak-auth:
	@echo "$(BOLD)Configurando Keycloak auth para Backstage...$(NC)"
	@kubectl apply -f backstage-auth-secret.yaml
	@kubectl create configmap backstage-auth-config \
		--from-file=app-config.auth.yaml \
		-n backstage \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "$(BOLD)Parcheando deployment para montar auth config y secrets...$(NC)"
	@kubectl patch deployment backstage -n backstage --type='json' -p='[ \
		{"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name": "auth-config", "configMap": {"name": "backstage-auth-config"}}}, \
		{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "auth-config", "mountPath": "/app/app-config.auth.yaml", "subPath": "app-config.auth.yaml", "readOnly": true}}, \
		{"op": "add", "path": "/spec/template/spec/containers/0/envFrom/-", "value": {"secretRef": {"name": "backstage-auth-secrets"}}}, \
		{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--config", "/app/app-config.yaml", "--config", "/app/app-config.auth.yaml"]} \
	]'
	@echo "$(GREEN)Configuracion de auth y secrets aplicados$(NC)"

## Aplicar politicas de permisos
apply-permissions:
	@echo "$(BOLD)Aplicando politicas de permisos...$(NC)"
	@echo ""
	@echo "$(YELLOW)Nota: Las politicas de permisos (permission-policy.ts) deben$(NC)"
	@echo "$(YELLOW)compilarse como parte del backend de Backstage.$(NC)"
	@echo ""
	@echo "$(BOLD)Politicas definidas:$(NC)"
	@echo "  $(GREEN)✓$(NC) platform-team: acceso total (admin)"
	@echo "  $(GREEN)✓$(NC) developers: pueden crear, no pueden eliminar"
	@echo "  $(GREEN)✓$(NC) Sin auth: acceso denegado"
	@echo ""
	@echo "Revisa: ../shared/permission-policy.ts"

## Reiniciar Backstage para aplicar cambios de auth
restart-backstage:
	@echo "$(BOLD)Reiniciando Backstage con configuracion de auth...$(NC)"
	@kubectl rollout restart deployment/backstage -n backstage
	@kubectl rollout status deployment/backstage -n backstage --timeout=180s
	@echo "$(GREEN)Backstage reiniciado$(NC)"

## Probar acceso con diferentes usuarios
test-access:
	@echo "$(BOLD)Prueba de acceso:$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Abre Backstage: http://localhost:30000$(NC)"
	@echo "   Deberia redirigir al login"
	@echo ""
	@echo "$(YELLOW)2. Login con Keycloak:$(NC)"
	@echo "   - admin-user / admin123 → Acceso completo"
	@echo "   - dev-user / dev123     → Acceso limitado (no puede eliminar)"
	@echo ""
	@echo "$(YELLOW)3. Login con GitHub:$(NC)"
	@echo "   - Requiere haber configurado OAuth App (make configure-github-auth)"
	@echo ""
	@echo "$(YELLOW)4. Verificaciones:$(NC)"
	@echo "   - admin-user puede crear Y eliminar entidades"
	@echo "   - dev-user puede crear pero NO eliminar entidades"
	@echo "   - Sin login: acceso denegado"

## Estado de los componentes de seguridad
status:
	@echo "$(BOLD)Estado de seguridad:$(NC)"
	@echo ""
	@echo "--- Keycloak ---"
	@kubectl get pods -n keycloak 2>/dev/null || echo "  Keycloak no desplegado"
	@echo ""
	@echo "--- Auth Secrets ---"
	@kubectl get secret backstage-auth-secrets -n backstage -o name 2>/dev/null && \
		echo "  $(GREEN)✓ Secret de auth existe$(NC)" || \
		echo "  $(RED)○ Secret de auth no encontrado$(NC)"
	@echo ""
	@echo "--- Auth Config ---"
	@kubectl get configmap backstage-auth-config -n backstage -o name 2>/dev/null && \
		echo "  $(GREEN)✓ ConfigMap de auth existe$(NC)" || \
		echo "  $(RED)○ ConfigMap de auth no encontrado$(NC)"

## Verificar todo
verify:
	@echo ""
	@echo "$(BOLD)Verificando seguridad...$(NC)"
	@echo ""
	@KEYCLOAK_READY=$$(kubectl get pods -n keycloak -l app=keycloak -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null); \
	if [ "$$KEYCLOAK_READY" = "True" ]; then \
		echo "$(GREEN)✓ Keycloak esta listo$(NC)"; \
	else \
		echo "$(YELLOW)⏳ Keycloak no esta listo aun$(NC)"; \
	fi
	@kubectl get secret backstage-auth-secrets -n backstage -o name >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Secrets de auth configurados$(NC)" || \
		echo "$(YELLOW)○ Secrets de auth pendientes$(NC)"
	@kubectl get configmap backstage-auth-config -n backstage -o name >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Configuracion de auth aplicada$(NC)" || \
		echo "$(YELLOW)○ Configuracion de auth pendiente$(NC)"
	@echo ""
	@echo "$(BOLD)Accesos:$(NC)"
	@echo "  Keycloak:  http://localhost:30004  (admin / admin123)"
	@echo "  Backstage: http://localhost:30000"

## Limpiar recursos de seguridad
clean:
	@echo "$(RED)Eliminando recursos de seguridad...$(NC)"
	@kubectl delete namespace keycloak --ignore-not-found=true
	@kubectl delete secret backstage-auth-secrets -n backstage --ignore-not-found=true 2>/dev/null || true
	@kubectl delete configmap backstage-auth-config -n backstage --ignore-not-found=true 2>/dev/null || true
	@if kubectl get deployment backstage -n backstage >/dev/null 2>&1; then \
		echo "$(YELLOW)Restaurando deployment de Backstage (imagen original, sin auth config)...$(NC)"; \
		kubectl set image deployment/backstage backstage=ghcr.io/backstage/backstage:1.35.0 -n backstage 2>/dev/null || true; \
		kubectl patch deployment backstage -n backstage --type='json' -p='[ \
			{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--config", "/app/app-config.yaml"]} \
		]' 2>/dev/null || true; \
	fi
	@docker rmi $(BACKSTAGE_OIDC_IMAGE) 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 07: Seguridad SSO y Politicas$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                       Todo (Keycloak + build + auth + permissions + verify)"
	@echo "  $(YELLOW)deploy-keycloak$(NC)           Desplegar Keycloak"
	@echo "  $(YELLOW)build-backstage-image$(NC)     Construir imagen Backstage con OIDC"
	@echo "  $(YELLOW)configure-github-auth$(NC)     Instrucciones para GitHub OAuth"
	@echo "  $(YELLOW)configure-keycloak-auth$(NC)   Configurar Keycloak en Backstage"
	@echo "  $(YELLOW)apply-permissions$(NC)         Aplicar politicas de permisos"
	@echo "  $(YELLOW)restart-backstage$(NC)         Reiniciar Backstage"
	@echo "  $(YELLOW)test-access$(NC)               Guia de pruebas de acceso"
	@echo "  $(YELLOW)status$(NC)                    Ver estado"
	@echo "  $(YELLOW)verify$(NC)                    Verificar instalacion"
	@echo "  $(YELLOW)clean$(NC)                     Limpiar todo"

.DEFAULT_GOAL := help
