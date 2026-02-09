\set ON_ERROR_STOP on
\pset pager off

-- ============================================================
-- 01_schema.sql
-- Creates the Group H schema (tables + PK/FK constraints).
--
-- This script is intended to be executed with psql so that
-- the :schema variable works.
--
-- Usage (recommended):
--   1) Set variables in .env:
--      DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, SCHEMA
--   2) Run the make target:
--      make schema
--
-- Notes:
--   - Run sql/00_reset.sql first (mode=drop) if you want a clean rebuild.
-- ============================================================

\if :{?schema}
\else
  \set schema sandbox
\endif

-- Schema is assumed to exist (no CREATE privilege).
SET search_path TO :"schema";

BEGIN;

CREATE TABLE "Department" (
  "department_id" serial PRIMARY KEY
);

CREATE TABLE "Program" (
  "program_id" serial PRIMARY KEY,
  "department_id" int NOT NULL
);

CREATE TABLE "Course" (
  "course_id" serial PRIMARY KEY,
  "department_id" int NOT NULL,
  "excludes_course_id" int,
  "hard_prerequisite_course_id" int
);

CREATE TABLE "Student" (
  "student_id" serial PRIMARY KEY,
  "program_id" int NOT NULL
);

CREATE TABLE "Instructor" (
  "instructor_id" serial PRIMARY KEY
);

CREATE TABLE "STUDENT_REQUESTED_ENROLLMENT_IN_COURSE" (
  "student_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("student_id", "course_id")
);

CREATE TABLE "STUDENT_ENROLLED_IN_COURSE" (
  "student_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("student_id", "course_id")
);

CREATE TABLE "STUDENT_PASSED_COURSE" (
  "student_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("student_id", "course_id")
);

CREATE TABLE "TEACHING_COURSE" (
  "instructor_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("instructor_id", "course_id")
);

CREATE TABLE "DEPARTMENT_INSTRUCTOR" (
  "department_id" int NOT NULL,
  "instructor_id" int NOT NULL,
  PRIMARY KEY ("department_id", "instructor_id")
);

CREATE TABLE "PROGRAM_REQUIRED_COURSE" (
  "program_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("program_id", "course_id")
);

CREATE TABLE "PROGRAM_ELECTIVE_COURSE" (
  "program_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("program_id", "course_id")
);

CREATE TABLE "PROGRAM_MANDATORY_ELECTIVE_COURSE" (
  "program_id" int NOT NULL,
  "course_id" int NOT NULL,
  PRIMARY KEY ("program_id", "course_id")
);

ALTER TABLE "Program"
  ADD FOREIGN KEY ("department_id") REFERENCES "Department" ("department_id");

ALTER TABLE "Course"
  ADD FOREIGN KEY ("department_id") REFERENCES "Department" ("department_id");

ALTER TABLE "Course"
  ADD FOREIGN KEY ("excludes_course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "Course"
  ADD FOREIGN KEY ("hard_prerequisite_course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "Student"
  ADD FOREIGN KEY ("program_id") REFERENCES "Program" ("program_id");

ALTER TABLE "STUDENT_REQUESTED_ENROLLMENT_IN_COURSE"
  ADD FOREIGN KEY ("student_id") REFERENCES "Student" ("student_id");

ALTER TABLE "STUDENT_REQUESTED_ENROLLMENT_IN_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "STUDENT_ENROLLED_IN_COURSE"
  ADD FOREIGN KEY ("student_id") REFERENCES "Student" ("student_id");

ALTER TABLE "STUDENT_ENROLLED_IN_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "STUDENT_PASSED_COURSE"
  ADD FOREIGN KEY ("student_id") REFERENCES "Student" ("student_id");

ALTER TABLE "STUDENT_PASSED_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "TEACHING_COURSE"
  ADD FOREIGN KEY ("instructor_id") REFERENCES "Instructor" ("instructor_id");

ALTER TABLE "TEACHING_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "DEPARTMENT_INSTRUCTOR"
  ADD FOREIGN KEY ("department_id") REFERENCES "Department" ("department_id");

ALTER TABLE "DEPARTMENT_INSTRUCTOR"
  ADD FOREIGN KEY ("instructor_id") REFERENCES "Instructor" ("instructor_id");

ALTER TABLE "PROGRAM_REQUIRED_COURSE"
  ADD FOREIGN KEY ("program_id") REFERENCES "Program" ("program_id");

ALTER TABLE "PROGRAM_REQUIRED_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "PROGRAM_ELECTIVE_COURSE"
  ADD FOREIGN KEY ("program_id") REFERENCES "Program" ("program_id");

ALTER TABLE "PROGRAM_ELECTIVE_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

ALTER TABLE "PROGRAM_MANDATORY_ELECTIVE_COURSE"
  ADD FOREIGN KEY ("program_id") REFERENCES "Program" ("program_id");

ALTER TABLE "PROGRAM_MANDATORY_ELECTIVE_COURSE"
  ADD FOREIGN KEY ("course_id") REFERENCES "Course" ("course_id");

COMMIT;
