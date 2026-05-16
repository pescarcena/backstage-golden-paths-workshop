# =============================================================================
# Paso 08: RBAC Multi-Capa
# Router: delega al subdirectorio segun MODE
# =============================================================================

MODE ?= k8s

.PHONY: all verify status demo-dev demo-admin clean help

all:
	@$(MAKE) -C $(MODE) all

verify:
	@$(MAKE) -C $(MODE) verify

status:
	@$(MAKE) -C $(MODE) status

demo-dev:
	@$(MAKE) -C $(MODE) demo-dev

demo-admin:
	@$(MAKE) -C $(MODE) demo-admin

clean:
	@$(MAKE) -C $(MODE) clean

help:
	@echo "Paso 08: RBAC Multi-Capa (MODE=$(MODE))"
	@$(MAKE) --no-print-directory -C $(MODE) help

.DEFAULT_GOAL := help
