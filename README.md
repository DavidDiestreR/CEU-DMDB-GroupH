# CEU-DMDB-GroupH

DNDS5020 — Data Management and Databases (CEU)

**Project summary:** This repository contains Group H’s PostgreSQL implementation of a unified course information system for CEU. The current focus is a **keys-first** schema (relations, PK/FK integrity, and core business rules), with views and data-loading scripts for reproducible setup.

**Short repo description (<350 chars):**  
PostgreSQL schema and views for a unified CEU course information system (DNDS5020). Group H models programs, departments, courses, instructors, and student enrollment, with reproducible setup scripts, loaders, and sanity checks.

---

## Goals

The database is designed to support queries such as:

- What courses a student **must** take vs can take (program requirements and electives).
- Course discovery across departments and programs.
- Planning based on prerequisites/exclusions and student course history.
- A clear foundation for adding descriptive attributes (credits, term, grading, etc.) later.

---

## Repository structure

```
CEU-DMDB-GroupH/
├─ README.md
├─ .gitignore
├─ .editorconfig
├─ .env.example
├─ Makefile

├─ docs/
│  ├─ proposal/
│  │  └─ Project_Proposal_Group_H.pdf
│  ├─ er/
│  └─ data_dictionary.md

├─ sql/
│  ├─ 00_reset.sql
│  ├─ 01_schema.sql
│  ├─ 02_constraints.sql
│  ├─ 03_views.sql
│  ├─ 04_load_public.sql
│  ├─ 05_seed.sql
│  └─ queries/
│     ├─ example_queries.sql
│     └─ grading_checks.sql

├─ data/
│  ├─ public/
│  ├─ private/
│  └─ README.md

└─ scripts/
   ├─ setup_db.sh
   └─ setup_db.ps1
```

### Notes
- `data/private/` is **never committed** (sensitive / raw exports).  
- `data/public/` may be committed (small, non-sensitive CSVs / demo extracts).

---

## Database overview (keys-first)

Core entities (subject to evolution as attributes are added):

- Departments, Programs, Courses, Students, Instructors

Relationship / junction tables (M:N or relationship-specific rules), for example:

- program requirements vs electives  
- teaching assignments  
- student course requests/enrollments/passed courses  
- course prerequisites and exclusions (as modeled in the schema)

> The schema emphasizes correct relationships and constraints first; descriptive attributes are added iteratively.

---

## Setup (CEU-hosted PostgreSQL)

CEU is expected to provide a PostgreSQL database/server where you deploy the schema and views.
You only need:
- `psql` (PostgreSQL client)
- your CEU DB connection details (host/user/password/dbname)

### 1) Install `psql`
- macOS (Homebrew): `brew install postgresql`
- Windows: install PostgreSQL and ensure `psql` is available in PATH
- Linux: install the PostgreSQL client via your package manager

### 2) Configure environment variables
Copy the template and fill in your values:

```bash
cp .env.example .env
```

Typical variables:
- `DB_HOST`
- `DB_PORT` (usually 5432)
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`

> Do **not** commit `.env`.

### 3) Deploy schema + views
Preferred (one command):
- macOS/Linux:
  ```bash
  bash scripts/setup_db.sh
  ```
- Windows (PowerShell):
  ```powershell
  .\scripts\setup_db.ps1
  ```

Manual execution (if you prefer):
```bash
psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD" -f sql/01_schema.sql
psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD" -f sql/03_views.sql
```

---

## Loading data

### Public data (`data/public/`)
When using a hosted server, server-side `COPY FROM '/path/on-server.csv'` may not work.
The recommended approach is client-side import using `psql` + `\copy` inside `sql/04_load_public.sql`.

Run:
```bash
psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD" -f sql/04_load_public.sql
```

### Private data (`data/private/`)
Keep sensitive files under `data/private/` and **never commit them**.
If you need to load private data, do it locally or via approved CEU methods, and document steps without uploading the data itself.

---

## Sanity checks

After deploying schema and loading data:

```bash
psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD" -f sql/queries/grading_checks.sql
```

This should include:
- row counts per table
- orphan / integrity checks (as applicable)
- duplicates on expected-unique keys

---

## Development workflow (recommended)

1. Update schema in `sql/01_schema.sql`
2. Add constraints/indexes in `sql/02_constraints.sql` (as attributes appear)
3. Add/update views in `sql/03_views.sql`
4. Add data loader logic in `sql/04_load_public.sql`
5. Keep project/report queries in `sql/queries/`
6. Run sanity checks before merges and before submission

---

## References / acknowledgements

- **dbdiagram.io** was used for ER model representation during the proposal stage.
- **URV intranet** is referenced as an example of consolidated course information; access is restricted and requires URV credentials (David’s login).

---

## Team (Group H)

- David Diestre Rubio
- Teodore Giorgobiani
- Thanika Haltrich
- Talha Sadiq
