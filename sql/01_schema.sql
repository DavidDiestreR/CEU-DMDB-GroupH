\set ON_ERROR_STOP on
\pset pager off

\if :{?schema}
\else
  \set schema project
\endif

set search_path to :"schema";

begin;


-- core tables

create table department (
  department_id      int generated always as identity primary key,
  department_name    varchar(200) not null unique
);

create table program (
  program_id                     int generated always as identity primary key,
  program_name                   varchar(200) not null unique,
  department_id                  int not null references department(department_id),
  corresponding_program_codes    varchar(50) not null,
  program_coordinator_email      varchar(254),
  program_learning_outcome       text,
  program_description            text
);

create table instructor (
  instructor_id          int generated always as identity primary key,
  instructor_first_name  varchar(100) not null,
  instructor_last_name   varchar(100) not null,
  instructor_email       varchar(254) unique,
  instructor_office      varchar(100)
);

create table student (
  student_id         int generated always as identity primary key,
  student_first_name varchar(100) not null,
  student_last_name  varchar(100) not null,
  student_email      varchar(254) unique,
  student_start_year int not null check (student_start_year >= 2020),
  program_id         int not null references program(program_id)
);

create table term (
  term_id    int generated always as identity primary key,
  term_name  varchar(100) not null,
  level      varchar(50) not null,
  start_date date not null,
  end_date   date not null,
  check (end_date > start_date),

  -- allow same term name in different levels to include different timeframes, but prevent duplicates within a level
  unique (term_name, level)
);

create table course (
  course_id      int generated always as identity primary key,
  course_code    varchar(20) not null,
  course_name    varchar(200) not null,
  us_credits     int not null check (us_credits > 0),
  ects_credits   int not null check (ects_credits > 0),
  department_id  int not null references department(department_id),
  term_id        int not null references term(term_id) on delete restrict,

  course_description       text,
  prereq_text              text,
  course_learning_outcomes text,

  excludes_course_id          int references course(course_id),

  level                                 varchar(50) not null,
  abbreviation                          varchar(8),
  course_type                           varchar(20),
  marking_scheme                        varchar(100),
  offered_for_non_degree_students       boolean not null default false,
  allow_repeats                         boolean not null default false,
  scheme                                varchar(100),

  learning_activities_and_teaching_methods  text,
  assessment                                text,
  course_contents                           text,
  background_and_overall_aim                text,
  contact_details                           text,

  check (excludes_course_id is null or excludes_course_id <> course_id),

  -- allow same course code/name in different terms, but prevent duplicates within a term
  unique (course_code, term_id),
  unique (course_name, term_id)
);

create index idx_course_department on course(department_id);
create index idx_course_term on course(term_id);
create index idx_student_program on student(program_id);


-- join tables

create table student_requested_enrollment_in_course (
  student_id int not null references student(student_id) on delete cascade,
  course_id  int not null references course(course_id) on delete restrict,
  primary key (student_id, course_id)
);

create table student_enrolled_in_course (
  student_id int not null references student(student_id) on delete cascade,
  course_id  int not null references course(course_id) on delete restrict,
  primary key (student_id, course_id)
);

create table student_passed_course (
  student_id int not null references student(student_id) on delete cascade,
  course_id  int not null references course(course_id) on delete restrict,
  grade      varchar(5) not null,
  primary key (student_id, course_id)
);

create table teaching_course (
  instructor_id int not null references instructor(instructor_id) on delete cascade,
  course_id     int not null references course(course_id) on delete restrict,
  primary key (instructor_id, course_id)
);

create table course_has_hard_prerequisite_course (
  course_id                   int not null references course(course_id) on delete cascade,
  hard_prerequisite_course_id int not null references course(course_id) on delete cascade,
  primary key (course_id, hard_prerequisite_course_id),
  check (course_id <> hard_prerequisite_course_id)
);


create table department_instructor (
  department_id int not null references department(department_id) on delete cascade,
  instructor_id int not null references instructor(instructor_id) on delete cascade,
  primary key (department_id, instructor_id)
);

create table program_mandatory_course (
  program_id            int not null references program(program_id) on delete cascade,
  course_id             int not null references course(course_id) on delete cascade,
  available_from_year_n int not null check (available_from_year_n >= 1),
  primary key (program_id, course_id)
);

create table program_elective_course (
  program_id            int not null references program(program_id) on delete cascade,
  course_id             int not null references course(course_id) on delete cascade,
  available_from_year_n int not null check (available_from_year_n >= 1),
  primary key (program_id, course_id)
);

create table program_mandatory_elective_course (
  program_id            int not null references program(program_id) on delete cascade,
  course_id             int not null references course(course_id) on delete cascade,
  available_from_year_n int not null check (available_from_year_n >= 1),
  primary key (program_id, course_id)
);

-- class and lesson

create table class (
  class_id   int generated always as identity primary key,
  class_name varchar(200) not null unique
);

create table lesson (
  lesson_id   int generated always as identity primary key,
  course_id   int not null references course(course_id) on delete cascade,
  class_id    int not null references class(class_id) on delete cascade,
  lesson_type varchar(50),
  lesson_time timestamp not null
);

create index idx_lesson_course on lesson(course_id);
commit;


