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

CREATE TABLE department (
  department_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  department_name    VARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE program (
  program_id                INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  program_name              VARCHAR(200) NOT NULL UNIQUE,
  department_id             INT NOT NULL REFERENCES department(department_id),
  program_coordinator_email VARCHAR(254),
  program_learning_outcome  TEXT,
  program_description       TEXT
);

CREATE TABLE instructor (
  instructor_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  instructor_first_name  VARCHAR(100) NOT NULL,
  instructor_last_name   VARCHAR(100) NOT NULL,
  instructor_email  VARCHAR(254) UNIQUE,
  instructor_office VARCHAR(100)
);

CREATE TABLE student (
  student_id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_first_name      VARCHAR(100) NOT NULL,
  student_last_name       VARCHAR(100) NOT NULL,
  student_email      VARCHAR(254) UNIQUE,
  student_start_year INT NOT NULL CHECK (student_start_year >= 2020),
  program_id         INT NOT NULL REFERENCES program(program_id)
);

CREATE TABLE term (
  term_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  term_name  VARCHAR(100) NOT NULL UNIQUE,  
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  CHECK (end_date > start_date)
);

-- Course table with self-referencing FKs for excludes and hard prerequisites

CREATE TABLE course (
  course_id                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  course_code    VARCHAR(20) NOT NULL UNIQUE,
  course_name               VARCHAR(200) NOT NULL UNIQUE,
  course_credits            INT NOT NULL CHECK (course_credits > 0),
  department_id             INT NOT NULL REFERENCES department(department_id),

  -- handwritten notes:
  course_description        TEXT,
  prereq_text               TEXT,                          
  course_learning_outcomes  TEXT,

  -- diagram fields:
  excludes_course_id        INT REFERENCES course(course_id),
  hard_prerequisite_course_id INT REFERENCES course(course_id),

  -- prevent self-references
  CHECK (excludes_course_id IS NULL OR excludes_course_id <> course_id),
  CHECK (hard_prerequisite_course_id IS NULL OR hard_prerequisite_course_id <> course_id)
);

-- Join tables 

CREATE TABLE course_term (
  course_id INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id   INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (course_id, term_id)
);

CREATE INDEX idx_course_term_term ON course_term(term_id);

CREATE TABLE student_requested_enrollment_in_course (
  student_id INT NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE student_enrolled_in_course (
  student_id INT NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE student_passed_course (
  student_id INT NOT NULL REFERENCES student(student_id) ON DELETE CASCADE,
  course_id  INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id    INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  grade      VARCHAR(5) NOT NULL,
  PRIMARY KEY (student_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE TABLE teaching_course (
  instructor_id INT NOT NULL REFERENCES instructor(instructor_id) ON DELETE CASCADE,
  course_id     INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id       INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  PRIMARY KEY (instructor_id, course_id, term_id),
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);


CREATE TABLE department_instructor (
  department_id INT NOT NULL REFERENCES department(department_id) ON DELETE CASCADE,
  instructor_id INT NOT NULL REFERENCES instructor(instructor_id) ON DELETE CASCADE,
  PRIMARY KEY (department_id, instructor_id)
);

CREATE TABLE program_required_course (
  program_id            INT NOT NULL REFERENCES program(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  available_from_year_n INT NOT NULL CHECK (available_from_year_n >= 1),
  PRIMARY KEY (program_id, course_id)
);

CREATE TABLE program_elective_course (
  program_id            INT NOT NULL REFERENCES program(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  available_from_year_n INT NOT NULL CHECK (available_from_year_n >= 1),
  PRIMARY KEY (program_id, course_id)
);

CREATE TABLE program_mandatory_elective_course (
  program_id            INT NOT NULL REFERENCES program(program_id) ON DELETE CASCADE,
  course_id             INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
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
  course_id   INT NOT NULL REFERENCES course(course_id) ON DELETE CASCADE,
  term_id     INT NOT NULL REFERENCES term(term_id) ON DELETE CASCADE,
  class_id    INT NOT NULL REFERENCES class(class_id) ON DELETE CASCADE,
  lesson_type VARCHAR(50),
  lesson_time TIMESTAMP NOT NULL,
  FOREIGN KEY (course_id, term_id) REFERENCES course_term(course_id, term_id) ON DELETE RESTRICT
);

CREATE INDEX idx_course_department ON course(department_id);
CREATE INDEX idx_student_program ON student(program_id);
CREATE INDEX idx_lesson_course_term ON lesson(course_id, term_id);

commit;