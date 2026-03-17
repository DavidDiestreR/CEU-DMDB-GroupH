.PHONY: help env hooks schema views load load-truncate reset-drop reset-truncate reset-view queries

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
	@echo "  views            Apply sql/03_views.sql"
	@echo "  load             Load data using sql/02_load.sql"
	@echo "  load-truncate    Truncate then load data"
	@echo "  reset-drop       Drop + recreate schema (sql/00_reset.sql mode=drop)"
	@echo "  reset-truncate   Truncate tables (sql/00_reset.sql mode=truncate)"
	@echo "  reset-view       Drop project materialized views only (sql/00_reset.sql mode=reset-view)"
	@echo "  queries          Run sql/queries/example_queries.sql"
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

views: $(ENV_FILE)
	$(PSQL_BASE) -f sql/03_views.sql "$(CONN)"
	
load: $(ENV_FILE)
	$(PSQL_BASE) -v is_windows=$(IS_WINDOWS) -f sql/02_load.sql "$(CONN)"

load-truncate: $(ENV_FILE)
	$(PSQL_BASE) -v truncate=1 -v is_windows=$(IS_WINDOWS) -f sql/02_load.sql "$(CONN)"

reset-drop: $(ENV_FILE)
	$(PSQL_BASE) -v mode=drop -f sql/00_reset.sql "$(CONN)"

reset-truncate: $(ENV_FILE)
	$(PSQL_BASE) -v mode=truncate -f sql/00_reset.sql "$(CONN)"

reset-view: $(ENV_FILE)
	$(PSQL_BASE) -v mode=reset-view -f sql/00_reset.sql "$(CONN)"

queries: $(ENV_FILE)
	$(PSQL_BASE) -f sql/queries/example_queries.sql "$(CONN)"
