# =============================================================================
# Paso 03: Golden Paths - Software Templates
# Soporta dos modos: k8s (default) y local
# =============================================================================

MODE ?= k8s

.PHONY: all verify clean help

all:
	@$(MAKE) -C $(MODE) all

verify:
	@$(MAKE) -C $(MODE) verify

clean:
	@$(MAKE) -C $(MODE) clean

help:
	@echo "Paso 03: Golden Paths (MODE=$(MODE))"
	@echo ""
	@echo "Uso: make <target> [MODE=k8s|local]"
	@echo ""
	@$(MAKE) -C $(MODE) help

.DEFAULT_GOAL := help
