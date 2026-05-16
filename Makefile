# =============================================================================
# Workshop: Backstage Golden Paths
# Makefile Global - Orquesta todos los pasos del workshop
# =============================================================================

.PHONY: all all-k8s all-local step-01 step-02 step-03 step-04 step-05 step-06 step-07 step-08 \
        verify verify-01 verify-02 verify-03 verify-04 verify-05 verify-06 verify-07 verify-08 \
        verify-all status clean help \
        tmux-init tmux-status tmux-attach tmux-stop tmux-restart-backstage

# Modo de ejecucion: k8s (default) o local
MODE ?= k8s

# Tmux session para servicios en background
TMUX_SESSION := goldenpaths

# Colores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
BLUE   := \033[0;34m
NC     := \033[0m # No Color
BOLD   := \033[1m

# Contador de verificaciones
PASS = $(GREEN)✓ PASS$(NC)
FAIL = $(RED)✗ FAIL$(NC)

# =============================================================================
# Targets principales
# =============================================================================

## Ejecutar todos los pasos del workshop en orden
all: step-01 step-02 step-03 step-04 step-05 step-06 step-07 step-08
	@echo ""
	@echo "$(GREEN)$(BOLD)========================================$(NC)"
	@echo "$(GREEN)$(BOLD)  Workshop completado! (MODE=$(MODE))   $(NC)"
	@echo "$(GREEN)$(BOLD)========================================$(NC)"
	@echo ""
	@echo "Ejecuta $(YELLOW)make verify-all$(NC) para comprobar todos los pasos"

## Shortcut: ejecutar todo en modo Kubernetes
all-k8s:
	@$(MAKE) all MODE=k8s

## Shortcut: ejecutar todo en modo local
all-local:
	@$(MAKE) all MODE=local

# =============================================================================
# Pasos individuales
# =============================================================================

## Paso 01: Configurar Kubernetes local (OrbStack + Kind)
step-01:
	@echo "$(BLUE)$(BOLD)>>> Paso 01: Kubernetes Local$(NC)"
	@$(MAKE) -C 01-kubernetes-local all MODE=$(MODE)

## Paso 02: Desplegar Backstage
step-02:
	@echo "$(BLUE)$(BOLD)>>> Paso 02: Deploy Backstage (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 02-deploy-backstage all MODE=$(MODE)
	@if [ "$(MODE)" = "local" ]; then \
		$(MAKE) --no-print-directory tmux-backstage; \
	fi

## Iniciar Backstage localmente (solo modo local)
start-backstage:
	@$(MAKE) -C 02-deploy-backstage/local start-backstage

## Paso 03: Configurar Golden Paths (Software Templates)
step-03:
	@echo "$(BLUE)$(BOLD)>>> Paso 03: Golden Paths (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 03-golden-paths all MODE=$(MODE)

## Paso 04: Configurar plugin de Kubernetes en Backstage
step-04:
	@echo "$(BLUE)$(BOLD)>>> Paso 04: Backstage Kubernetes Plugin (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 04-backstage-kubernetes-plugin all MODE=$(MODE)

## Paso 05: GitOps conceptos (solo documentacion)
step-05:
	@echo "$(BLUE)$(BOLD)>>> Paso 05: GitOps Conceptos$(NC)"
	@echo "$(YELLOW)  Este paso es solo lectura. Revisa 05-gitops-conceptos/README.md$(NC)"

## Paso 06: Desplegar ArgoCD e integrar con Backstage
step-06:
	@echo "$(BLUE)$(BOLD)>>> Paso 06: Deploy GitOps (ArgoCD) (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 06-deploy-gitops all MODE=$(MODE)

## Paso 07: Configurar seguridad, SSO y politicas
step-07:
	@echo "$(BLUE)$(BOLD)>>> Paso 07: Seguridad SSO y Politicas (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 07-seguridad-sso-politicas all MODE=$(MODE)
	@if [ "$(MODE)" = "local" ]; then \
		echo "$(YELLOW)Reiniciando Backstage para aplicar auth...$(NC)"; \
		$(MAKE) --no-print-directory tmux-restart-backstage; \
	fi

## Paso 08: RBAC Multi-Capa (del login al deploy)
step-08:
	@echo "$(BLUE)$(BOLD)>>> Paso 08: RBAC Multi-Capa (MODE=$(MODE))$(NC)"
	@$(MAKE) -C 08-rbac-multi-capa all MODE=$(MODE)
	@if [ "$(MODE)" = "local" ]; then \
		echo "$(YELLOW)Reiniciando Backstage para aplicar org catalog...$(NC)"; \
		$(MAKE) --no-print-directory tmux-restart-backstage; \
	fi

# =============================================================================
# Verificaciones individuales
# =============================================================================

## Verificar Paso 01: Cluster Kind + Gateway API
verify-01:
	@echo "$(BLUE)$(BOLD)[Verify 01] Kubernetes Local$(NC)"
	@ERRORS=0; \
	if kind get clusters 2>/dev/null | grep -q "backstage-workshop"; then \
		echo "  $(PASS) Cluster Kind 'backstage-workshop' existe"; \
	else \
		echo "  $(FAIL) Cluster Kind no encontrado"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get nodes --context kind-backstage-workshop >/dev/null 2>&1; then \
		READY=$$(kubectl get nodes --context kind-backstage-workshop --no-headers 2>/dev/null | grep -c " Ready"); \
		TOTAL=$$(kubectl get nodes --context kind-backstage-workshop --no-headers 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$READY" = "$$TOTAL" ]; then \
			echo "  $(PASS) Todos los nodos Ready ($$READY/$$TOTAL)"; \
		else \
			echo "  $(FAIL) Nodos no listos ($$READY/$$TOTAL Ready)"; \
			ERRORS=$$((ERRORS+1)); \
		fi; \
	else \
		echo "  $(FAIL) No se puede conectar al cluster"; \
		ERRORS=$$((ERRORS+1)); \
	fi; \
	if kubectl get gatewayclass cloud-provider-kind >/dev/null 2>&1; then \
		echo "  $(PASS) GatewayClass 'cloud-provider-kind' disponible"; \
	else \
		echo "  $(YELLOW)⚠ GatewayClass no encontrado (opcional: ejecuta sudo cloud-provider-kind --gateway-channel standard)$(NC)"; \
	fi; \
	if kubectl get gateway -n gateway-infra workshop-gateway >/dev/null 2>&1; then \
		ADDR=$$(kubectl get gateway -n gateway-infra workshop-gateway -o jsonpath='{.status.addresses[0].value}' 2>/dev/null); \
		if [ -n "$$ADDR" ]; then \
			echo "  $(PASS) Gateway 'workshop-gateway' con IP $$ADDR"; \
		else \
			echo "  $(YELLOW)⚠ Gateway existe pero sin IP asignada (opcional)$(NC)"; \
		fi; \
	else \
		echo "  $(YELLOW)⚠ Gateway 'workshop-gateway' no encontrado (opcional)$(NC)"; \
	fi; \
	if [ $$ERRORS -gt 0 ]; then \
		echo ""; \
		echo "  $(RED)$$ERRORS problema(s) encontrado(s) en Paso 01$(NC)"; \
		exit 1; \
	else \
		echo "  $(GREEN)$(BOLD)Paso 01 OK$(NC)"; \
	fi

## Verificar Paso 02: Backstage + PostgreSQL
verify-02:
	@echo "$(BLUE)$(BOLD)[Verify 02] Backstage (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 02-deploy-backstage verify MODE=$(MODE)

## Verificar Paso 03: Golden Paths
verify-03:
	@echo "$(BLUE)$(BOLD)[Verify 03] Golden Paths (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 03-golden-paths verify MODE=$(MODE)

## Verificar Paso 04: Kubernetes Plugin (RBAC)
verify-04:
	@echo "$(BLUE)$(BOLD)[Verify 04] Backstage Kubernetes Plugin (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 04-backstage-kubernetes-plugin verify MODE=$(MODE)

## Verificar Paso 05: GitOps Conceptos (solo documentacion)
verify-05:
	@echo "$(BLUE)$(BOLD)[Verify 05] GitOps Conceptos$(NC)"
	@if [ -f "05-gitops-conceptos/README.md" ]; then \
		echo "  $(PASS) README.md existe"; \
		echo "  $(GREEN)$(BOLD)Paso 05 OK$(NC) (solo documentacion)"; \
	else \
		echo "  $(FAIL) README.md no encontrado"; \
		exit 1; \
	fi

## Verificar Paso 06: ArgoCD
verify-06:
	@echo "$(BLUE)$(BOLD)[Verify 06] ArgoCD (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 06-deploy-gitops verify MODE=$(MODE)

## Verificar Paso 07: Seguridad (Keycloak + Auth config)
verify-07:
	@echo "$(BLUE)$(BOLD)[Verify 07] Seguridad SSO y Politicas (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 07-seguridad-sso-politicas verify MODE=$(MODE)

## Verificar Paso 08: RBAC Multi-Capa
verify-08:
	@echo "$(BLUE)$(BOLD)[Verify 08] RBAC Multi-Capa (MODE=$(MODE))$(NC)"
	@$(MAKE) --no-print-directory -C 08-rbac-multi-capa verify MODE=$(MODE)

# =============================================================================
# Verificacion global
# =============================================================================

## Verificar un paso especifico: make verify step=01
verify:
ifndef step
	@echo "$(RED)Uso: make verify step=XX$(NC)"
	@echo "Ejemplo: make verify step=01"
	@echo ""
	@echo "Para verificar todos: $(YELLOW)make verify-all$(NC)"
else
	@$(MAKE) verify-$(step)
endif

## Verificar todos los pasos del workshop
verify-all:
	@echo "$(BOLD)============================================$(NC)"
	@echo "$(BOLD)  Verificacion completa del Workshop$(NC)"
	@echo "$(BOLD)============================================$(NC)"
	@echo ""
	@TOTAL=8; PASSED=0; FAILED=0; \
	for STEP in 01 02 03 04 05 06 07 08; do \
		if $(MAKE) --no-print-directory verify-$$STEP; then \
			PASSED=$$((PASSED+1)); \
		else \
			FAILED=$$((FAILED+1)); \
		fi; \
		echo ""; \
	done; \
	echo "$(BOLD)============================================$(NC)"; \
	echo "$(BOLD)  Resultado: $$PASSED/$$TOTAL pasos verificados$(NC)"; \
	if [ $$FAILED -gt 0 ]; then \
		echo "  $(RED)$$FAILED paso(s) con problemas$(NC)"; \
	fi; \
	echo "$(BOLD)============================================$(NC)"; \
	if [ $$FAILED -gt 0 ]; then exit 1; fi

# =============================================================================
# Utilidades
# =============================================================================

## Mostrar estado de todos los componentes del workshop
status:
	@echo "$(BOLD)============================================$(NC)"
	@echo "$(BOLD)  Estado del Workshop Golden Paths$(NC)"
	@echo "$(BOLD)============================================$(NC)"
	@echo ""
	@echo "$(BOLD)[Paso 01] Kubernetes Local$(NC)"
	@if kind get clusters 2>/dev/null | grep -q "backstage-workshop"; then \
		echo "  $(GREEN)● Cluster Kind activo$(NC)"; \
		kubectl get nodes --no-headers 2>/dev/null | while read line; do \
			echo "    $$line"; \
		done; \
	else \
		echo "  $(RED)○ Cluster Kind no encontrado$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)[Paso 01] Gateway API$(NC)"
	@if kubectl get gateway -n gateway-infra workshop-gateway >/dev/null 2>&1; then \
		ADDR=$$(kubectl get gateway -n gateway-infra workshop-gateway -o jsonpath='{.status.addresses[0].value}' 2>/dev/null); \
		echo "  $(GREEN)● Gateway activo (IP: $$ADDR)$(NC)"; \
	else \
		echo "  $(RED)○ Gateway no configurado$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)[Paso 02] Backstage$(NC)"
	@if kubectl get namespace backstage >/dev/null 2>&1; then \
		echo "  $(GREEN)● Namespace backstage existe$(NC)"; \
		kubectl get pods -n backstage --no-headers 2>/dev/null | while read line; do \
			echo "    $$line"; \
		done; \
	else \
		echo "  $(RED)○ Backstage no desplegado$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)[Paso 06] ArgoCD$(NC)"
	@if kubectl get namespace argocd >/dev/null 2>&1; then \
		echo "  $(GREEN)● Namespace argocd existe$(NC)"; \
		kubectl get pods -n argocd --no-headers 2>/dev/null | while read line; do \
			echo "    $$line"; \
		done; \
	else \
		echo "  $(RED)○ ArgoCD no desplegado$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)[Paso 07] Keycloak$(NC)"
	@if kubectl get namespace keycloak >/dev/null 2>&1; then \
		echo "  $(GREEN)● Namespace keycloak existe$(NC)"; \
		kubectl get pods -n keycloak --no-headers 2>/dev/null | while read line; do \
			echo "    $$line"; \
		done; \
	else \
		echo "  $(RED)○ Keycloak no desplegado$(NC)"; \
	fi
	@echo ""
	@echo "$(BOLD)[Paso 08] RBAC Multi-Capa$(NC)"
	@if kubectl get namespace apps-dev >/dev/null 2>&1; then \
		echo "  $(GREEN)● Namespace apps-dev existe$(NC)"; \
	else \
		echo "  $(RED)○ Namespace apps-dev no encontrado$(NC)"; \
	fi
	@if kubectl get namespace apps-platform >/dev/null 2>&1; then \
		echo "  $(GREEN)● Namespace apps-platform existe$(NC)"; \
	else \
		echo "  $(RED)○ Namespace apps-platform no encontrado$(NC)"; \
	fi
	@if kubectl get appproject team-dev -n argocd >/dev/null 2>&1; then \
		echo "  $(GREEN)● AppProject team-dev configurado$(NC)"; \
	else \
		echo "  $(RED)○ AppProject team-dev no encontrado$(NC)"; \
	fi

# =============================================================================
# Tmux - Servicios en background
# =============================================================================

## Inicializar sesion tmux (si no existe)
tmux-init:
	@command -v tmux >/dev/null 2>&1 || { echo "$(RED)Error: tmux no esta instalado. macOS: brew install tmux | Linux/WSL2: sudo apt-get install tmux$(NC)"; exit 1; }
	@if ! tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux new-session -d -s $(TMUX_SESSION) -n shell; \
		echo "$(GREEN)Sesion tmux '$(TMUX_SESSION)' creada$(NC)"; \
	fi

## Lanzar cloud-provider-kind en tmux
tmux-cloud-provider: tmux-init
	@if tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^cloud-provider$$'; then \
		echo "$(YELLOW)cloud-provider-kind ya esta en tmux$(NC)"; \
	else \
		tmux new-window -t $(TMUX_SESSION) -n cloud-provider; \
		tmux send-keys -t $(TMUX_SESSION):cloud-provider 'sudo cloud-provider-kind --gateway-channel standard' Enter; \
		echo "$(GREEN)cloud-provider-kind lanzado en tmux (ventana: cloud-provider)$(NC)"; \
		echo "$(YELLOW)Si necesitas ingresar password: make tmux-attach w=cloud-provider$(NC)"; \
	fi

## Lanzar kubectl proxy en tmux
tmux-kubectl-proxy: tmux-init
	@if tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^kubectl-proxy$$'; then \
		echo "$(YELLOW)kubectl proxy ya esta en tmux$(NC)"; \
	else \
		tmux new-window -t $(TMUX_SESSION) -n kubectl-proxy; \
		tmux send-keys -t $(TMUX_SESSION):kubectl-proxy 'kubectl proxy' Enter; \
		echo "$(GREEN)kubectl proxy lanzado en tmux (ventana: kubectl-proxy)$(NC)"; \
	fi

## Lanzar Backstage en tmux
tmux-backstage: tmux-init
	@if tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^backstage$$'; then \
		echo "$(YELLOW)Backstage ya esta en tmux$(NC)"; \
	else \
		tmux new-window -t $(TMUX_SESSION) -n backstage; \
		tmux send-keys -t $(TMUX_SESSION):backstage 'cd $(CURDIR) && make start-backstage' Enter; \
		echo "$(GREEN)Backstage lanzado en tmux (ventana: backstage)$(NC)"; \
	fi

## Reiniciar Backstage en tmux (mata la ventana y la relanza)
tmux-restart-backstage: tmux-init
	@if tmux list-windows -t $(TMUX_SESSION) -F '#W' 2>/dev/null | grep -q '^backstage$$'; then \
		tmux send-keys -t $(TMUX_SESSION):backstage C-c; \
		sleep 2; \
		tmux send-keys -t $(TMUX_SESSION):backstage 'cd $(CURDIR) && make start-backstage' Enter; \
		echo "$(GREEN)Backstage reiniciado en tmux$(NC)"; \
	else \
		$(MAKE) --no-print-directory tmux-backstage; \
	fi

## Ver estado de la sesion tmux
tmux-status:
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		echo "$(BOLD)Sesion tmux '$(TMUX_SESSION)':$(NC)"; \
		echo ""; \
		tmux list-windows -t $(TMUX_SESSION) -F '  #{window_index}: #{window_name} #{?window_active,(activa),}' 2>/dev/null; \
	else \
		echo "$(YELLOW)No hay sesion tmux activa$(NC)"; \
	fi

## Conectar a la sesion tmux (opcional: w=ventana)
tmux-attach:
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		if [ -n "$(w)" ]; then \
			tmux select-window -t $(TMUX_SESSION):$(w); \
		fi; \
		tmux attach-session -t $(TMUX_SESSION); \
	else \
		echo "$(YELLOW)No hay sesion tmux activa. Ejecuta: make tmux-init$(NC)"; \
	fi

## Detener todos los servicios tmux
tmux-stop:
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux kill-session -t $(TMUX_SESSION); \
		echo "$(GREEN)Sesion tmux '$(TMUX_SESSION)' eliminada$(NC)"; \
	else \
		echo "$(YELLOW)No hay sesion tmux activa$(NC)"; \
	fi

## Limpiar todos los recursos (orden inverso)
clean:
	@echo "$(RED)$(BOLD)Limpiando todos los recursos del workshop...$(NC)"
	@echo ""
	-@$(MAKE) -C 08-rbac-multi-capa clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 07-seguridad-sso-politicas clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 06-deploy-gitops clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 04-backstage-kubernetes-plugin clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 03-golden-paths clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 02-deploy-backstage clean MODE=$(MODE) 2>/dev/null || true
	-@$(MAKE) -C 01-kubernetes-local destroy 2>/dev/null || true
	@if tmux has-session -t $(TMUX_SESSION) 2>/dev/null; then \
		tmux kill-session -t $(TMUX_SESSION); \
		echo "$(GREEN)Sesion tmux '$(TMUX_SESSION)' eliminada$(NC)"; \
	fi
	@echo "$(YELLOW)Eliminando app local de Backstage...$(NC)"
	@rm -rf 02-deploy-backstage/local/backstage-app 2>/dev/null || true
	@echo ""
	@echo "$(GREEN)Limpieza completada$(NC)"

## Mostrar esta ayuda
help:
	@echo "$(BOLD)============================================$(NC)"
	@echo "$(BOLD)  Workshop: Backstage Golden Paths$(NC)"
	@echo "$(BOLD)============================================$(NC)"
	@echo ""
	@echo "$(BOLD)Uso:$(NC) make [target] [MODE=k8s|local]"
	@echo ""
	@echo "$(BOLD)Modos:$(NC)"
	@echo "  $(YELLOW)MODE=k8s$(NC)       Backstage en Kubernetes (default)"
	@echo "  $(YELLOW)MODE=local$(NC)     Backstage local con yarn start"
	@echo ""
	@echo "$(BOLD)Targets principales:$(NC)"
	@echo "  $(YELLOW)all$(NC)            Ejecutar todos los pasos del workshop"
	@echo "  $(YELLOW)all-k8s$(NC)        Shortcut: make all MODE=k8s"
	@echo "  $(YELLOW)all-local$(NC)      Shortcut: make all MODE=local"
	@echo "  $(YELLOW)verify-all$(NC)     Verificar todos los pasos"
	@echo "  $(YELLOW)verify step=XX$(NC) Verificar un paso especifico (ej: make verify step=02)"
	@echo "  $(YELLOW)status$(NC)         Mostrar estado de todos los componentes"
	@echo "  $(YELLOW)clean$(NC)          Limpiar todos los recursos (orden inverso)"
	@echo "  $(YELLOW)help$(NC)           Mostrar esta ayuda"
	@echo ""
	@echo "$(BOLD)Tmux (servicios en background):$(NC)"
	@echo "  $(YELLOW)tmux-cloud-provider$(NC)  Lanzar cloud-provider-kind (solo MODE=k8s)"
	@echo "  $(YELLOW)tmux-kubectl-proxy$(NC)   Lanzar kubectl proxy"
	@echo "  $(YELLOW)tmux-backstage$(NC)       Lanzar Backstage (yarn start)"
	@echo "  $(YELLOW)tmux-restart-backstage$(NC) Reiniciar Backstage (aplica nuevos configs)"
	@echo "  $(YELLOW)tmux-status$(NC)          Ver ventanas tmux activas"
	@echo "  $(YELLOW)tmux-attach$(NC)          Conectar a tmux (w=ventana)"
	@echo "  $(YELLOW)tmux-stop$(NC)            Detener todos los servicios"
	@echo ""
	@echo "$(BOLD)Pasos individuales:$(NC)"
	@echo "  $(YELLOW)step-01$(NC)        Kubernetes local (OrbStack + Kind)"
	@echo "  $(YELLOW)step-02$(NC)        Desplegar Backstage"
	@echo "  $(YELLOW)step-03$(NC)        Golden Paths (Software Templates)"
	@echo "  $(YELLOW)step-04$(NC)        Plugin de Kubernetes en Backstage"
	@echo "  $(YELLOW)step-05$(NC)        GitOps conceptos (solo lectura)"
	@echo "  $(YELLOW)step-06$(NC)        Desplegar ArgoCD"
	@echo "  $(YELLOW)step-07$(NC)        Seguridad SSO y politicas"
	@echo "  $(YELLOW)step-08$(NC)        RBAC Multi-Capa (del login al deploy)"
	@echo ""
	@echo "$(BOLD)Verificaciones individuales:$(NC)"
	@echo "  $(YELLOW)verify-01$(NC)      Cluster Kind + Gateway API"
	@echo "  $(YELLOW)verify-02$(NC)      Backstage + PostgreSQL"
	@echo "  $(YELLOW)verify-03$(NC)      Golden Paths (archivos template)"
	@echo "  $(YELLOW)verify-04$(NC)      Kubernetes Plugin (RBAC)"
	@echo "  $(YELLOW)verify-05$(NC)      GitOps conceptos (documentacion)"
	@echo "  $(YELLOW)verify-06$(NC)      ArgoCD"
	@echo "  $(YELLOW)verify-07$(NC)      Keycloak + Auth config"
	@echo "  $(YELLOW)verify-08$(NC)      RBAC Multi-Capa"

.DEFAULT_GOAL := help
