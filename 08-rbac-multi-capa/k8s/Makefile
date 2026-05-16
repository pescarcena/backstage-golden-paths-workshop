# =============================================================================
# Paso 08: RBAC Multi-Capa - Modo Kubernetes
# Del login al deploy: control de acceso en cada capa
# =============================================================================

.PHONY: all create-namespaces apply-k8s-rbac apply-argocd-projects \
        apply-argocd-rbac apply-argocd-oidc register-org \
        demo-dev demo-admin status verify clean help

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: create-namespaces apply-k8s-rbac apply-argocd-projects apply-argocd-rbac apply-argocd-oidc register-org verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 08 completado! RBAC multi-capa configurado.$(NC)"
	@echo ""
	@echo "$(BOLD)Prueba con:$(NC)"
	@echo "  $(YELLOW)make demo-dev$(NC)     Simular lo que puede hacer dev-user"
	@echo "  $(YELLOW)make demo-admin$(NC)   Simular lo que puede hacer admin-user"

## Crear namespaces de trabajo
create-namespaces:
	@echo "$(BOLD)Creando namespaces de trabajo...$(NC)"
	@kubectl apply -f ../shared/namespaces.yaml
	@echo "$(GREEN)Namespaces apps-dev y apps-platform creados$(NC)"

## Aplicar RBAC de Kubernetes por namespace
apply-k8s-rbac:
	@echo "$(BOLD)Aplicando RBAC de Kubernetes por namespace...$(NC)"
	@kubectl apply -f ../shared/k8s-rbac-namespaced.yaml
	@echo "$(GREEN)RoleBindings aplicados:$(NC)"
	@echo "  developers    -> edit en apps-dev, view en apps-platform"
	@echo "  platform-team -> edit en apps-dev y apps-platform"

## Crear AppProjects en ArgoCD
apply-argocd-projects:
	@echo "$(BOLD)Creando AppProjects en ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-projects.yaml
	@echo "$(GREEN)AppProjects creados:$(NC)"
	@echo "  team-dev      -> destino: solo apps-dev"
	@echo "  team-platform -> destino: cualquier namespace"

## Aplicar RBAC de ArgoCD (mapeo grupo Keycloak -> rol ArgoCD)
apply-argocd-rbac:
	@echo "$(BOLD)Aplicando RBAC de ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-rbac-patch.yaml
	@echo "$(GREEN)RBAC de ArgoCD configurado:$(NC)"
	@echo "  developers    -> role:developer (get/sync en team-dev)"
	@echo "  platform-team -> role:admin (acceso total)"

## Configurar ArgoCD para autenticar via Keycloak OIDC
apply-argocd-oidc:
	@echo "$(BOLD)Configurando OIDC en ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-oidc-patch.yaml
	@kubectl rollout restart deployment/argocd-server -n argocd
	@echo "$(GREEN)ArgoCD configurado para login via Keycloak$(NC)"
	@echo "$(YELLOW)Esperando reinicio del argocd-server...$(NC)"
	@kubectl wait --namespace argocd \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=120s 2>/dev/null || true
	@echo "$(GREEN)ArgoCD listo$(NC)"

## Registrar entidades de organizacion en Backstage
register-org:
	@echo "$(BOLD)Registrando entidades User/Group en Backstage...$(NC)"
	@kubectl create configmap backstage-org-catalog \
		--from-file=org.yaml=../shared/org.yaml \
		-n backstage \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo "$(BOLD)Montando org.yaml en Backstage y agregando al catalog...$(NC)"
	@kubectl patch deployment backstage -n backstage --type='json' -p='[ \
		{"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name": "org-catalog", "configMap": {"name": "backstage-org-catalog"}}}, \
		{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "org-catalog", "mountPath": "/app/org.yaml", "subPath": "org.yaml", "readOnly": true}} \
	]' 2>/dev/null || echo "$(YELLOW)Patch ya aplicado$(NC)"
	@echo "$(BOLD)Actualizando catalog con org.yaml...$(NC)"
	@CURRENT=$$(kubectl get configmap backstage-app-config -n backstage -o jsonpath='{.data.app-config\.yaml}' 2>/dev/null); \
	if echo "$$CURRENT" | grep -q "org.yaml"; then \
		echo "$(YELLOW)org.yaml ya registrado en catalog$(NC)"; \
	else \
		UPDATED=$$(echo "$$CURRENT" | sed 's|locations: \[\]|locations:\n      - type: file\n        target: /app/org.yaml\n        rules:\n          - allow: [User, Group]|'); \
		kubectl create configmap backstage-app-config \
			--from-literal="app-config.yaml=$$UPDATED" \
			-n backstage \
			--dry-run=client -o yaml | kubectl apply -f -; \
		echo "$(GREEN)org.yaml agregado al catalog$(NC)"; \
	fi
	@kubectl rollout restart deployment/backstage -n backstage
	@echo "$(GREEN)Backstage reiniciado con org catalog$(NC)"

## Demo: que puede hacer dev-user
demo-dev:
	@echo "$(BOLD)============================================$(NC)"
	@echo "$(BOLD)  Demo: dev-user (grupo: developers)$(NC)"
	@echo "$(BOLD)============================================$(NC)"
	@echo ""
	@echo "$(BOLD)1. Deploy en apps-dev (PERMITIDO)$(NC)"
	@echo "$(YELLOW)   Creando Application en proyecto team-dev -> namespace apps-dev...$(NC)"
	@kubectl apply -f ../shared/demo-app-dev.yaml
	@echo "$(GREEN)   ✓ Application 'demo-nginx-dev' creada exitosamente$(NC)"
	@echo ""
	@sleep 2
	@echo "$(BOLD)2. Deploy en apps-platform (RECHAZADO por ArgoCD)$(NC)"
	@echo "$(YELLOW)   Creando Application en proyecto team-dev -> namespace apps-platform...$(NC)"
	@if kubectl apply -f ../shared/demo-app-platform.yaml 2>&1; then \
		echo ""; \
		echo "$(YELLOW)   La Application se creo pero ArgoCD la rechazara al sincronizar.$(NC)"; \
		echo "$(YELLOW)   Verificando estado...$(NC)"; \
		sleep 5; \
		STATUS=$$(kubectl get application demo-nginx-platform -n argocd -o jsonpath='{.status.conditions[0].message}' 2>/dev/null); \
		if [ -n "$$STATUS" ]; then \
			echo "$(RED)   ✗ ArgoCD: $$STATUS$(NC)"; \
		else \
			HEALTH=$$(kubectl get application demo-nginx-platform -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null); \
			SYNC=$$(kubectl get application demo-nginx-platform -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null); \
			echo "$(RED)   ✗ Estado: health=$$HEALTH sync=$$SYNC (destino no permitido en team-dev)$(NC)"; \
		fi; \
	else \
		echo "$(RED)   ✗ Rechazado: destino apps-platform no permitido en proyecto team-dev$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)3. kubectl directo en apps-platform (RECHAZADO por K8s RBAC)$(NC)"
	@echo "$(YELLOW)   Simulando: kubectl create deployment test --image=nginx -n apps-platform$(NC)"
	@echo "$(YELLOW)   (Con ServiceAccount de developers, esto seria denegado por RoleBinding)$(NC)"
	@echo "$(RED)   ✗ K8s RBAC: developers solo tiene 'view' en apps-platform$(NC)"
	@echo ""
	@echo "$(BOLD)Resumen dev-user:$(NC)"
	@echo "  $(GREEN)✓$(NC) Desplegar en apps-dev via ArgoCD"
	@echo "  $(RED)✗$(NC) Desplegar en apps-platform via ArgoCD (AppProject lo impide)"
	@echo "  $(RED)✗$(NC) Modificar recursos en apps-platform via kubectl (RBAC lo impide)"
	@echo "  $(RED)✗$(NC) Eliminar entidades en Backstage (Permission Policy lo impide)"

## Demo: que puede hacer admin-user
demo-admin:
	@echo "$(BOLD)============================================$(NC)"
	@echo "$(BOLD)  Demo: admin-user (grupo: platform-team)$(NC)"
	@echo "$(BOLD)============================================$(NC)"
	@echo ""
	@echo "$(BOLD)1. Deploy en apps-dev (PERMITIDO)$(NC)"
	@echo "$(YELLOW)   admin-user puede usar proyecto team-platform para desplegar en cualquier namespace$(NC)"
	@echo "$(GREEN)   ✓ Permitido: team-platform no tiene restriccion de destino$(NC)"
	@echo ""
	@echo "$(BOLD)2. Deploy en apps-platform (PERMITIDO)$(NC)"
	@echo "$(YELLOW)   Usando proyecto team-platform -> namespace apps-platform$(NC)"
	@echo "$(GREEN)   ✓ Permitido: team-platform acepta cualquier namespace$(NC)"
	@echo ""
	@echo "$(BOLD)3. kubectl directo en cualquier namespace (PERMITIDO)$(NC)"
	@echo "$(GREEN)   ✓ Permitido: platform-team tiene 'edit' en todos los namespaces$(NC)"
	@echo ""
	@echo "$(BOLD)4. Eliminar entidades en Backstage (PERMITIDO)$(NC)"
	@echo "$(GREEN)   ✓ Permitido: Permission Policy da ALLOW a platform-team$(NC)"
	@echo ""
	@echo "$(BOLD)Resumen admin-user:$(NC)"
	@echo "  $(GREEN)✓$(NC) Desplegar en cualquier namespace via ArgoCD"
	@echo "  $(GREEN)✓$(NC) Modificar recursos en cualquier namespace via kubectl"
	@echo "  $(GREEN)✓$(NC) Eliminar entidades en Backstage"

## Ver estado de los recursos del paso 08
status:
	@echo "$(BOLD)Estado Paso 08: RBAC Multi-Capa$(NC)"
	@echo ""
	@echo "$(BOLD)--- Namespaces de trabajo ---$(NC)"
	@kubectl get namespace apps-dev apps-platform 2>/dev/null || echo "  No creados"
	@echo ""
	@echo "$(BOLD)--- RoleBindings en apps-dev ---$(NC)"
	@kubectl get rolebindings -n apps-dev 2>/dev/null || echo "  Sin RoleBindings"
	@echo ""
	@echo "$(BOLD)--- RoleBindings en apps-platform ---$(NC)"
	@kubectl get rolebindings -n apps-platform 2>/dev/null || echo "  Sin RoleBindings"
	@echo ""
	@echo "$(BOLD)--- AppProjects en ArgoCD ---$(NC)"
	@kubectl get appprojects -n argocd 2>/dev/null || echo "  Sin AppProjects"
	@echo ""
	@echo "$(BOLD)--- Applications de demo ---$(NC)"
	@kubectl get applications -n argocd 2>/dev/null || echo "  Sin Applications"

## Verificar la configuracion
verify:
	@echo ""
	@echo "$(BOLD)Verificando RBAC Multi-Capa...$(NC)"
	@echo ""
	@ERRORS=0; \
	if kubectl get namespace apps-dev >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ Namespace apps-dev existe$(NC)"; \
	else \
		echo "  $(RED)✗ Namespace apps-dev no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get namespace apps-platform >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ Namespace apps-platform existe$(NC)"; \
	else \
		echo "  $(RED)✗ Namespace apps-platform no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get rolebinding developers-edit -n apps-dev >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ RoleBinding developers-edit en apps-dev$(NC)"; \
	else \
		echo "  $(RED)✗ RoleBinding developers-edit no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get rolebinding developers-view -n apps-platform >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ RoleBinding developers-view en apps-platform$(NC)"; \
	else \
		echo "  $(RED)✗ RoleBinding developers-view no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get appproject team-dev -n argocd >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ AppProject team-dev existe$(NC)"; \
		DEST=$$(kubectl get appproject team-dev -n argocd -o jsonpath='{.spec.destinations[0].namespace}' 2>/dev/null); \
		echo "    destino permitido: $$DEST"; \
	else \
		echo "  $(RED)✗ AppProject team-dev no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get appproject team-platform -n argocd >/dev/null 2>&1; then \
		echo "  $(GREEN)✓ AppProject team-platform existe$(NC)"; \
		DEST=$$(kubectl get appproject team-platform -n argocd -o jsonpath='{.spec.destinations[0].namespace}' 2>/dev/null); \
		echo "    destino permitido: $$DEST"; \
	else \
		echo "  $(RED)✗ AppProject team-platform no encontrado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get configmap argocd-rbac-cm -n argocd -o jsonpath='{.data.policy\.csv}' 2>/dev/null | grep -q "role:developer"; then \
		echo "  $(GREEN)✓ ArgoCD RBAC configurado (role:developer)$(NC)"; \
	else \
		echo "  $(RED)✗ ArgoCD RBAC no configurado$(NC)"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get configmap argocd-cm -n argocd -o jsonpath='{.data.oidc\.config}' 2>/dev/null | grep -q "Keycloak"; then \
		echo "  $(GREEN)✓ ArgoCD OIDC configurado (Keycloak)$(NC)"; \
	else \
		echo "  $(YELLOW)⚠ ArgoCD OIDC no configurado (login SSO no disponible)$(NC)"; \
	fi; \
	echo ""; \
	if [ $$ERRORS -gt 0 ]; then \
		echo "  $(RED)$$ERRORS problema(s) encontrado(s)$(NC)"; \
		exit 1; \
	else \
		echo "  $(GREEN)$(BOLD)Paso 08 OK$(NC)"; \
	fi

## Limpiar recursos del paso 08
clean:
	@echo "$(RED)Eliminando recursos del paso 08...$(NC)"
	@kubectl delete -f ../shared/demo-app-dev.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/demo-app-platform.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/argocd-projects.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/k8s-rbac-namespaced.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete configmap backstage-org-catalog -n backstage --ignore-not-found=true 2>/dev/null || true
	@kubectl delete namespace apps-dev apps-platform --ignore-not-found=true 2>/dev/null || true
	@echo "$(GREEN)Paso 08 limpiado$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 08: RBAC Multi-Capa$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                  Todo (namespaces + RBAC + ArgoCD + org + verify)"
	@echo "  $(YELLOW)create-namespaces$(NC)    Crear apps-dev y apps-platform"
	@echo "  $(YELLOW)apply-k8s-rbac$(NC)       Aplicar RoleBindings por namespace"
	@echo "  $(YELLOW)apply-argocd-projects$(NC) Crear AppProjects en ArgoCD"
	@echo "  $(YELLOW)apply-argocd-rbac$(NC)    Configurar RBAC de ArgoCD"
	@echo "  $(YELLOW)apply-argocd-oidc$(NC)    Conectar ArgoCD con Keycloak"
	@echo "  $(YELLOW)register-org$(NC)         Registrar User/Group en Backstage"
	@echo "  $(YELLOW)demo-dev$(NC)             Simular permisos de dev-user"
	@echo "  $(YELLOW)demo-admin$(NC)           Simular permisos de admin-user"
	@echo "  $(YELLOW)status$(NC)               Ver estado"
	@echo "  $(YELLOW)verify$(NC)               Verificar configuracion"
	@echo "  $(YELLOW)clean$(NC)                Limpiar recursos"

.DEFAULT_GOAL := help
