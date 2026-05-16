# =============================================================================
# Paso 08: RBAC Multi-Capa - Modo Local
# ArgoCD y K8s RBAC siempre corren en el cluster Kind
# =============================================================================

.PHONY: all check-prereqs create-namespaces apply-k8s-rbac apply-argocd-projects \
        apply-argocd-rbac apply-argocd-oidc register-org \
        demo-dev demo-admin status verify clean help

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
		echo "$(RED)Error: Cluster Kind no encontrado. Ejecuta primero paso 01.$(NC)"; \
		exit 1; \
	}
	@kubectl get namespace argocd >/dev/null 2>&1 || { \
		echo "$(RED)Error: ArgoCD no desplegado. Ejecuta primero paso 06.$(NC)"; \
		exit 1; \
	}

## Ejecutar todo el paso
all: check-prereqs create-namespaces apply-k8s-rbac apply-argocd-projects apply-argocd-rbac apply-argocd-oidc register-org verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 08 (local) completado! RBAC multi-capa configurado.$(NC)"
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
	@echo "$(GREEN)RoleBindings aplicados$(NC)"

## Crear AppProjects en ArgoCD
apply-argocd-projects:
	@echo "$(BOLD)Creando AppProjects en ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-projects.yaml
	@echo "$(GREEN)AppProjects creados$(NC)"

## Aplicar RBAC de ArgoCD
apply-argocd-rbac:
	@echo "$(BOLD)Aplicando RBAC de ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-rbac-patch.yaml
	@echo "$(GREEN)RBAC de ArgoCD configurado$(NC)"

## Configurar ArgoCD OIDC
apply-argocd-oidc:
	@echo "$(BOLD)Configurando OIDC en ArgoCD...$(NC)"
	@kubectl apply -f ../shared/argocd-oidc-patch.yaml
	@kubectl rollout restart deployment/argocd-server -n argocd
	@echo "$(YELLOW)Esperando reinicio del argocd-server...$(NC)"
	@kubectl wait --namespace argocd \
		--for=condition=ready pod \
		--selector=app.kubernetes.io/name=argocd-server \
		--timeout=120s 2>/dev/null || true
	@echo "$(GREEN)ArgoCD listo$(NC)"

## Registrar org en Backstage (copiar org.yaml al proyecto)
register-org:
	@echo "$(BOLD)Copiando org.yaml al proyecto Backstage...$(NC)"
	@if [ -d "$(BACKSTAGE_APP_DIR)" ]; then \
		cp ../shared/org.yaml $(BACKSTAGE_APP_DIR)/org.yaml; \
		echo "$(GREEN)org.yaml copiado a $(BACKSTAGE_APP_DIR)/$(NC)"; \
		echo "$(YELLOW)Agrega esta location al app-config.yaml de Backstage:$(NC)"; \
		echo "  catalog:"; \
		echo "    locations:"; \
		echo "      - type: file"; \
		echo "        target: org.yaml"; \
		echo "        rules:"; \
		echo "          - allow: [User, Group]"; \
	else \
		echo "$(YELLOW)Backstage app no encontrada. Registra org.yaml manualmente.$(NC)"; \
	fi

## Demo: que puede hacer dev-user
demo-dev:
	@$(MAKE) --no-print-directory -C ../k8s demo-dev

## Demo: que puede hacer admin-user
demo-admin:
	@$(MAKE) --no-print-directory -C ../k8s demo-admin

## Ver estado
status:
	@$(MAKE) --no-print-directory -C ../k8s status

## Verificar
verify:
	@$(MAKE) --no-print-directory -C ../k8s verify

## Limpiar
clean:
	@echo "$(RED)Eliminando recursos del paso 08...$(NC)"
	@kubectl delete -f ../shared/demo-app-dev.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/demo-app-platform.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/argocd-projects.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete -f ../shared/k8s-rbac-namespaced.yaml --ignore-not-found=true 2>/dev/null || true
	@kubectl delete namespace apps-dev apps-platform --ignore-not-found=true 2>/dev/null || true
	@rm -f $(BACKSTAGE_APP_DIR)/org.yaml 2>/dev/null || true
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf ../../02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo "$(GREEN)Paso 08 limpiado$(NC)"

## Ayuda
help:
	@echo "$(BOLD)Paso 08: RBAC Multi-Capa (Local)$(NC)"
	@echo ""
	@echo "$(YELLOW)Nota: K8s RBAC y ArgoCD corren en el cluster Kind (igual que modo k8s).$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                  Todo (namespaces + RBAC + ArgoCD + org + verify)"
	@echo "  $(YELLOW)demo-dev$(NC)             Simular permisos de dev-user"
	@echo "  $(YELLOW)demo-admin$(NC)           Simular permisos de admin-user"
	@echo "  $(YELLOW)status$(NC)               Ver estado"
	@echo "  $(YELLOW)verify$(NC)               Verificar"
	@echo "  $(YELLOW)clean$(NC)                Limpiar"

.DEFAULT_GOAL := help
