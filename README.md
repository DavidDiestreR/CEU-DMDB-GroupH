# CEU-DMDB-GroupH

DNDS5020 - Data Management and Databases (CEU)

**Project summary:** This repository contains Group H's PostgreSQL implementation of a unified CEU course information system. It includes the database schema (entities, attributes, relationships), sample/public datasets, and a set of views and loading scripts to make setup and testing reproducible across environments.

---

## Goals

The database is designed to support queries such as:

- A student searching for all courses available to them across departments, filtered by schedule and prerequisites.
- An advisor querying which courses satisfy specific degree requirements.
- An administrator identifying scheduling conflicts for courses required by the same cohort.
- A faculty member viewing their consolidated teaching schedule and room assignments.
- A student comparing course descriptions, instructors, and credits from a single source.

---

## Repository structure

```
CEU-DMDB-GroupH/
├─ README.md
├─ .gitignore
├─ .gitattributes
├─ .env.example
├─ Makefile
├─ .github/
├─ .githooks/
├─ docs/
│  ├─ week_4_project_proposal/
│  ├─ week_8_project_prototype/
│  └─ week_12_project_presentation/
├─ sql/
│  ├─ 00_reset.sql
│  ├─ 01_schema.sql
│  ├─ 02_load.sql
│  ├─ 03_views.sql
│  └─ queries/
│     └─ example_queries.sql
├─ data_preprocessing/
└─ data/
   ├─ public/
   ├─ private/
   └─ dump_folder/
```

### Notes
- `data/private/` is **never committed** (sensitive / raw exports); its contents are ignored by git.
- `data/public/` may be committed (small, non-sensitive CSVs / demo extracts).
- `data/dump_folder/` is where you drop CSVs to load; its contents are ignored by git.

---

## Database overview

Core tables:

- `department`, `program`, `instructor`, `student`, `term`, `course`, `class`, `lesson`

Relationship / junction tables:

- `teaching_course`: links instructors to courses
- `department_instructor`: associates instructors with departments
- `student_requested_enrollment_in_course`, `student_enrolled_in_course`, `student_passed_course`: represent requested, active, and completed student-course relationships
- `course_has_hard_prerequisite_course`: stores hard prerequisite dependencies between courses
- `program_mandatory_course`, `program_elective_course`, `program_mandatory_elective_course`: capture the different ways courses belong to program requirements

---

## Setup (CEU-hosted PostgreSQL)

For this project CEU has provided a PostgreSQL server where we can deploy the schema and views.
For the setup we need:
- `psql` (PostgreSQL client)
- `git`
- `make` (Windows: `winget install ezwinports.make`)
- CEU DB connection details

### Make commands (shortcuts)

The Makefile reads connection variables from `.env` and provides short aliases for the longer `psql` commands below. Use `make help` to get information on all available make commands.

Modify the `.env` file or use inline variables on make commands when you need a different schema. Example:
```bash
make SCHEMA=$SCHEMA load
```

### 1) Install `psql`
- macOS: `brew install postgresql`
- Windows: install PostgreSQL and ensure `psql` is available in PATH (ChatGPT can help with adding it to the path)
- Linux: install the PostgreSQL client via your package manager

### 2) Configure environment variables
Copy the template and add the private environment values for each variable in the new `.env` file:

```bash
cp .env.example .env
```

Make equivalent:
```bash
make env
```

> It is important **not** to commit `.env` (in principle, .gitignore manages this directly).

### 2.5) Install git hooks (required per clone)

Run once after cloning:

```bash
make hooks
```

This sets `core.hooksPath=.githooks` so the notebook-cleaning pre-commit hook runs on macOS/Windows/Linux.

### 3) Deploy schema + views
Run these commands from the repo root. This executes everything on the **remote database you connect to**.

```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -f sql/01_schema.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -f sql/03_views.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalents:
```bash
make schema
make views
```

**Why the flags?**
- `-v schema=$SCHEMA`: deploys everything into a dedicated schema (recommended on shared/hosted databases).
- `-v ON_ERROR_STOP=1`: stops immediately if anything fails, preventing partial setup.

**Note on permissions**
- This project assumes the target schema already exists.

---

## Idempotency (safe re-execution)

During development/testing, scripts will often be re-run. To make this safe:

- **Views** should be defined with `CREATE OR REPLACE VIEW` in `sql/03_views.sql`.  
  This allows re-running the file without "already exists" errors and keeps definitions up to date.  
  Note: removing a view from the file does not delete it from the database; use `sql/00_reset.sql` (mode=drop) for a clean rebuild.


- **Indexes** should use `CREATE INDEX IF NOT EXISTS ...` for idempotency.

---

## Loading data (directory-based loader)

`sql/02_load.sql` is a simple loader designed to:
- load CSVs from `data/dump_folder/`
- load only those tables (skipping missing ones)

Place your CSVs in `data/dump_folder/` before running `make load`.

### Example (load from dump folder)
```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -f sql/02_load.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalent:
```bash
make load
```

### Re-load from scratch (truncate first)
```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -v truncate=1 -f sql/02_load.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalent:
```bash
make load-truncate
```

**Important:** `.xlsx` cannot be imported directly by psql's `\copy`. Convert Excel files to CSV first (one CSV per table).

---

## Reset (clean state)

`sql/00_reset.sql` provides a safe reset for development/testing without dropping the whole database.

### Full reset (drop schema)
```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -v mode=drop -f sql/00_reset.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalent:
```bash
make reset-drop
```

### Data-only reset (drop data, keep schema/objects)
```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -v mode=truncate -f sql/00_reset.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalent:
```bash
make reset-truncate
```

---

## Example queries

Run premade queries:

```bash
psql -v ON_ERROR_STOP=1 -v schema=$SCHEMA -f sql/queries/example_queries.sql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD"
```

Make equivalent:
```bash
make queries
```
---

## Notebook hygiene enforcement

To enforce cleared Jupyter notebooks across macOS/Windows/Linux, this repo includes:
- Workflow: `.github/workflows/notebook-hygiene.yml`
- Checker script: `.githooks/notebook_hygiene.py --check-all`

The check fails if any tracked `.ipynb` file contains:
- Non-empty `outputs`
- Non-null `execution_count`
- `metadata.widgets`