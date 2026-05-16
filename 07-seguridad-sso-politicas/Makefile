# =============================================================================
# Paso 07: Seguridad - SSO y Politicas
# Soporta dos modos: k8s (default) y local
# =============================================================================

MODE ?= k8s

.PHONY: all verify status clean help

all:
	@$(MAKE) -C $(MODE) all

verify:
	@$(MAKE) -C $(MODE) verify

status:
	@$(MAKE) -C $(MODE) status

clean:
	@$(MAKE) -C $(MODE) clean

help:
	@echo "Paso 07: Seguridad SSO y Politicas (MODE=$(MODE))"
	@echo ""
	@echo "Uso: make <target> [MODE=k8s|local]"
	@echo ""
	@$(MAKE) -C $(MODE) help

.DEFAULT_GOAL := help
