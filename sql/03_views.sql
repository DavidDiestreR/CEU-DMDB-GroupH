\set ON_ERROR_STOP on
\pset pager off

\if :{?schema}
\else
  \set schema project
\endif

set search_path to :"schema";

begin;

-- ============================================================
-- VIEW 1: Timetable for a given student
--
-- Shows the weekly timetable for one student based on the courses
-- they are currently enrolled in.
-- Change the student_id in the WHERE clause to inspect a different student.
-- ============================================================

select exists (
  select 1
  from pg_matviews
  where schemaname = current_schema()
    and matviewname = 'student_timetable'
) as student_timetable_exists
\gset

\if :student_timetable_exists
refresh materialized view student_timetable;
\else
create materialized view student_timetable as
select
  weekday,
  course,
  time,
  lesson_type,
  room
from (
  select
    lower(l.weekday) as weekday,
    case lower(l.weekday)
      when 'monday' then 1
      when 'tuesday' then 2
      when 'wednesday' then 3
      when 'thursday' then 4
      when 'friday' then 5
    end as weekday_number,
    c.course_code || ' - ' || c.course_name as course,
    l.start_time::text || ' - ' || l.end_time::text as time,
    l.lesson_type,
    cl.class_name as room,
    l.start_time,
    l.end_time,
    c.course_code,
    l.lesson_id
  from student_enrolled_in_course sec
  join student s on s.student_id = sec.student_id
  join course c on c.course_id = sec.course_id
  join lesson l on l.course_id = c.course_id
  join class cl on cl.class_id = l.class_id
  where s.student_id = 201
) timetable_rows
order by weekday_number,
         start_time,
         end_time,
         course_code,
         lesson_id;

\endif

commit;