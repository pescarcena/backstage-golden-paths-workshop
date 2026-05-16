# =============================================================================
# Paso 04: Backstage Kubernetes Plugin
# =============================================================================

.PHONY: all apply-rbac configure restart-backstage verify clean help

# Colores
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m
BOLD   := \033[1m

## Ejecutar todo el paso
all: apply-rbac configure restart-backstage verify
	@echo ""
	@echo "$(GREEN)$(BOLD)Paso 04 completado! Plugin de Kubernetes configurado.$(NC)"

## Aplicar RBAC para que Backstage lea recursos de K8s
apply-rbac:
	@echo "$(BOLD)Aplicando RBAC para Backstage...$(NC)"
	@kubectl apply -f ../shared/k8s-rbac.yaml
	@echo "$(GREEN)RBAC aplicado$(NC)"

## Actualizar configuracion de Backstage con el plugin de K8s
configure:
	@echo "$(BOLD)Actualizando configuracion de Backstage con plugin Kubernetes...$(NC)"
	@echo ""
	@echo "Fusionando configuracion del plugin K8s con el ConfigMap existente..."
	@kubectl create configmap backstage-k8s-config \
		--from-file=app-config.k8s-plugin.yaml \
		-n backstage \
		--dry-run=client -o yaml | kubectl apply -f -
	@echo ""
	@echo "$(GREEN)Configuracion actualizada$(NC)"
	@echo "$(YELLOW)Nota: La imagen oficial de Backstage ya incluye el plugin de Kubernetes.$(NC)"
	@echo "$(YELLOW)Si usas una imagen custom, asegurate de incluir:$(NC)"
	@echo "  @backstage/plugin-kubernetes"
	@echo "  @backstage/plugin-kubernetes-backend"

## Reiniciar Backstage para aplicar cambios
restart-backstage:
	@echo "$(BOLD)Reiniciando Backstage...$(NC)"
	@kubectl rollout restart deployment/backstage -n backstage
	@echo "$(YELLOW)Esperando a que Backstage reinicie...$(NC)"
	@kubectl rollout status deployment/backstage -n backstage --timeout=180s
	@echo "$(GREEN)Backstage reiniciado$(NC)"

## Verificar que el plugin funciona
verify:
	@echo ""
	@echo "$(BOLD)Verificando plugin de Kubernetes...$(NC)"
	@echo ""
	@echo "--- RBAC ---"
	@kubectl get clusterrole backstage-kubernetes-reader -o name 2>/dev/null && \
		echo "$(GREEN)✓ ClusterRole creado$(NC)" || \
		echo "$(RED)✗ ClusterRole no encontrado$(NC)"
	@kubectl get clusterrolebinding backstage-kubernetes-reader -o name 2>/dev/null && \
		echo "$(GREEN)✓ ClusterRoleBinding creado$(NC)" || \
		echo "$(RED)✗ ClusterRoleBinding no encontrado$(NC)"
	@echo ""
	@echo "--- Backstage ServiceAccount ---"
	@kubectl get serviceaccount backstage -n backstage -o name 2>/dev/null && \
		echo "$(GREEN)✓ ServiceAccount existe$(NC)" || \
		echo "$(RED)✗ ServiceAccount no encontrado$(NC)"
	@echo ""
	@echo "--- Test de permisos ---"
	@kubectl auth can-i list pods --as=system:serviceaccount:backstage:backstage 2>/dev/null && \
		echo "$(GREEN)✓ Backstage puede listar pods$(NC)" || \
		echo "$(RED)✗ Backstage NO puede listar pods$(NC)"
	@kubectl auth can-i list deployments --as=system:serviceaccount:backstage:backstage 2>/dev/null && \
		echo "$(GREEN)✓ Backstage puede listar deployments$(NC)" || \
		echo "$(RED)✗ Backstage NO puede listar deployments$(NC)"

## Limpiar recursos
clean:
	@echo "$(RED)Eliminando RBAC de Backstage...$(NC)"
	@kubectl delete -f ../shared/k8s-rbac.yaml --ignore-not-found=true
	@kubectl delete configmap backstage-k8s-config -n backstage --ignore-not-found=true
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar ayuda
help:
	@echo "$(BOLD)Paso 04: Backstage Kubernetes Plugin$(NC)"
	@echo ""
	@echo "$(BOLD)Targets:$(NC)"
	@echo "  $(YELLOW)all$(NC)                Todo (RBAC + config + restart + verify)"
	@echo "  $(YELLOW)apply-rbac$(NC)         Aplicar permisos RBAC"
	@echo "  $(YELLOW)configure$(NC)          Actualizar configuracion del plugin"
	@echo "  $(YELLOW)restart-backstage$(NC)  Reiniciar Backstage"
	@echo "  $(YELLOW)verify$(NC)             Verificar que todo funciona"
	@echo "  $(YELLOW)clean$(NC)              Limpiar recursos"

.DEFAULT_GOAL := help
