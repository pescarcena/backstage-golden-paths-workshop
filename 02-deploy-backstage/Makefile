# =============================================================================
# Paso 02: Desplegar Backstage
# Soporta dos modos: k8s (default) y local
# =============================================================================

MODE ?= k8s

.PHONY: all verify status start-backstage clean help

all:
	@$(MAKE) -C $(MODE) all

verify:
	@$(MAKE) -C $(MODE) verify

status:
	@$(MAKE) -C $(MODE) status

start-backstage:
	@$(MAKE) -C local start-backstage

clean:
	@$(MAKE) -C $(MODE) clean

help:
	@echo "Paso 02: Deploy Backstage (MODE=$(MODE))"
	@echo ""
	@echo "Uso: make <target> [MODE=k8s|local]"
	@echo ""
	@$(MAKE) -C $(MODE) help

.DEFAULT_GOAL := help
