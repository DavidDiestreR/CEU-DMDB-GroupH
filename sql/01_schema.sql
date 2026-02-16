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
-- Check 

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

-- Core tables

CREATE TABLE "Department" (
  department_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  department_name    VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE "Program" (
  program_id                INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  program_name              VARCHAR(200) NOT NULL UNIQUE,
  department_id             INT NOT NULL REFERENCES "Department"(department_id),
  program_coordinator_email VARCHAR(254),
  program_learning_outcome  TEXT,
  program_description       TEXT
);

CREATE TABLE "Instructor" (
  instructor_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  instructor_first_name  VARCHAR(100) NOT NULL,
  instructor_last_name   VARCHAR(100) NOT NULL,
  instructor_email  VARCHAR(254) UNIQUE,
  instructor_office VARCHAR(100)
);

CREATE TABLE "Student" (
  student_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_first_name      VARCHAR(100) NOT NULL,
  student_last_name       VARCHAR(100) NOT NULL,
  student_email      VARCHAR(254) UNIQUE,
  student_start_year INT NOT NULL CHECK (student_start_year >= 2020),
  program_id         INT NOT NULL REFERENCES "Program"(program_id)
);

CREATE TABLE term (
  term_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  term_name  VARCHAR(100) NOT NULL UNIQUE,  
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  CHECK (end_date > start_date)
);

-- Course table with self-referencing FKs for excludes and hard prerequisites

CREATE TABLE "Course" (
  course_id                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  course_code    VARCHAR(20) NOT NULL UNIQUE,
  course_name               VARCHAR(200) NOT NULL UNIQUE,
  course_credits            INT NOT NULL CHECK (course_credits > 0),
  department_id             INT NOT NULL REFERENCES "Department"(department_id),

  -- handwritten notes:
  course_description        TEXT,
  prereq_text               TEXT,                          
  course_learning_outcomes  TEXT,

  -- diagram fields:
  excludes_course_id        INT REFERENCES "Course"(course_id),
  hard_prerequisite_course_id INT REFERENCES "Course"(course_id),

  -- prevent self-references
  CHECK (excludes_course_id IS NULL OR excludes_course_id <> course_id),
  CHECK (hard_prerequisite_course_id IS NULL OR hard_prerequisite_course_id <> course_id)
);

-- Join tables 

CREATE TABLE course_term (
  course_id INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id   INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (course_id, term_id)
);

CREATE INDEX idx_course_term_term ON course_term(term_id);

CREATE TABLE "STUDENT_REQUESTED_ENROLLMENT_IN_COURSE" (
  student_id INT NOT NULL REFERENCES "Student"(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE "STUDENT_ENROLLED_IN_COURSE" (
  student_id INT NOT NULL REFERENCES "Student"(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE "STUDENT_PASSED_COURSE" (
  student_id INT NOT NULL REFERENCES "Student"(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  grade      VARCHAR(5) NOT NULL,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE "TEACHING_COURSE" (
  instructor_id INT NOT NULL REFERENCES "Instructor"(instructor_id) ON DELETE CASCADE,
  course_id     INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id       INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (instructor_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);


CREATE TABLE "DEPARTMENT_INSTRUCTOR" (
  department_id INT NOT NULL REFERENCES "Department"(department_id) ON DELETE CASCADE,
  instructor_id INT NOT NULL REFERENCES "Instructor"(instructor_id) ON DELETE CASCADE,
  PRIMARY KEY (department_id, instructor_id)
);

CREATE TABLE "PROGRAM_REQUIRED_COURSE" (
  program_id            INT NOT NULL REFERENCES "Program"(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  available_from_year_n INT NOT NULL CHECK (available_from_year_n >= 1),
  PRIMARY KEY (program_id, course_id)
);

CREATE TABLE "PROGRAM_ELECTIVE_COURSE" (
  program_id            INT NOT NULL REFERENCES "Program"(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  available_from_year_n INT NOT NULL CHECK (available_from_year_n >= 1),
  PRIMARY KEY (program_id, course_id)
);

CREATE TABLE "PROGRAM_MANDATORY_ELECTIVE_COURSE" (
  program_id            INT NOT NULL REFERENCES "Program"(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  available_from_year_n INT NOT NULL CHECK (available_from_year_n >= 1),
  PRIMARY KEY (program_id, course_id)

);

-- Class and Lesson 

CREATE TABLE class (
  class_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  class_name VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE lesson (
  lesson_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  course_id   INT NOT NULL REFERENCES "Course"(course_id) ON DELETE CASCADE,
  term_id     INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  class_id    INT NOT NULL REFERENCES class(class_id) ON DELETE CASCADE,
  lesson_type VARCHAR(50),
  lesson_time TIMESTAMP NOT NULL,
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE INDEX idx_course_department ON "Course"(department_id);
CREATE INDEX idx_student_program ON "Student"(program_id);
CREATE INDEX idx_lesson_course_term ON lesson(course_id, term_id);

commit;
