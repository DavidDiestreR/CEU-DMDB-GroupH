.PHONY: help env hooks schema constraints views deploy load load-truncate reset-drop reset-truncate sanity workflow

ENV_FILE := .env

-include $(ENV_FILE)
export

PSQL ?= psql
SCHEMA ?= sandbox
IS_WINDOWS := $(if $(filter Windows_NT,$(OS)),true,false)

CONN = host=$(DB_HOST) port=$(DB_PORT) dbname=$(DB_NAME) user=$(DB_USER) password=$(DB_PASSWORD)
PSQL_BASE = $(PSQL) -v ON_ERROR_STOP=1 -v schema=$(SCHEMA)

help:
	@echo "Targets:"
	@echo "  env              Copy .env.example to .env"
	@echo "  hooks            Install repo git hooks (.githooks)"
	@echo "  schema           Apply sql/01_schema.sql"
	@echo "  constraints      Apply sql/02_constraints.sql"
	@echo "  views            Apply sql/03_views.sql"
	@echo "  deploy           Apply schema + constraints + views"
	@echo "  load             Load data using sql/04_load_from_dir.sql"
	@echo "  load-truncate    Truncate then load data"
	@echo "  reset-drop       Drop + recreate schema (sql/00_reset.sql mode=drop)"
	@echo "  reset-truncate   Truncate tables (sql/00_reset.sql mode=truncate)"
	@echo "  sanity           Run sql/queries/sanity_checks.sql"
	@echo "  workflow         End-to-end recommended workflow"
	@echo ""
	@echo "Variables:"
	@echo "  SCHEMA=$(SCHEMA)"

$(ENV_FILE): .env.example
	cp .env.example $(ENV_FILE)

env: $(ENV_FILE)

hooks:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit || true
	@echo "Git hooks installed. Current hooksPath: $$(git config --get core.hooksPath)"

schema: $(ENV_FILE)
	$(PSQL_BASE) -f sql/01_schema.sql "$(CONN)"

constraints: $(ENV_FILE)
	$(PSQL_BASE) -f sql/02_constraints.sql "$(CONN)"

views: $(ENV_FILE)
	$(PSQL_BASE) -f sql/03_views.sql "$(CONN)"

deploy: schema constraints views

load: $(ENV_FILE)
	$(PSQL_BASE) -v is_windows=$(IS_WINDOWS) -f sql/04_load_from_dir.sql "$(CONN)"

load-truncate: $(ENV_FILE)
	$(PSQL_BASE) -v truncate=1 -v is_windows=$(IS_WINDOWS) -f sql/04_load_from_dir.sql "$(CONN)"

reset-drop: $(ENV_FILE)
	$(PSQL_BASE) -v mode=drop -f sql/00_reset.sql "$(CONN)"

reset-truncate: $(ENV_FILE)
	$(PSQL_BASE) -v mode=truncate -f sql/00_reset.sql "$(CONN)"

sanity: $(ENV_FILE)
	$(PSQL_BASE) -f sql/queries/sanity_checks.sql "$(CONN)"

workflow: reset-drop deploy load sanity
