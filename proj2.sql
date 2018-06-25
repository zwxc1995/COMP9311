--Q1:

drop type if exists RoomRecord cascade;
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);

create or replace function Q1(course_id integer)
    returns SETOF RoomRecord
as $$
Declare N RoomRecord%rowtype;
Begin
if $1 not in (select id from courses) then
raise exception'INVALID COURSEID';
end if;
For N in Select B.R,E.R 
From
(Select count(rooms.id) R
From rooms,
(Select count(course_enrolments.student) S
From course_enrolments
Where course_enrolments.course=$1
) A
Where rooms.capacity>=A.S) B,
(Select count(rooms.id) R
From rooms,
(Select count(course_enrolments.student) S
From course_enrolments
Where course_enrolments.course=$1
) C,
(Select count(course_enrolment_waitlist.student) S
From course_enrolment_waitlist
Where course_enrolment_waitlist.course=$1
) D
Where rooms.capacity>=C.S+D.S) E
loop
Return next N;
End loop;
Return;
End;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


--Q2:

drop type if exists TeachingRecord cascade;
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);

create or replace function Q2(staff_id integer)
	returns setof TeachingRecord
as $$
Declare N TeachingRecord%rowtype;
Begin
if $1 not in (select staff from course_staff) then
raise exception'INVALID STAFFID';
end if;
For N in Select course_staff.course as cid,right(cast(semesters.year as varchar),2)||lower(left(cast(semesters.term as varchar),1))||right(cast(semesters.term as varchar),1) as term,subjects.code,subjects.name as name,coalesce(subjects.uoc,null) as uoc,
cast(round(avg(course_enrolments.mark),0) as int) as average_mark,max(course_enrolments.mark) as highest_mark,cast(round(G.median,0) as int) as median_mark,count(course_enrolments.student) as totlEnrols
From course_staff,semesters,courses,subjects,course_enrolments,
(
Select data_with_rownumber.B as H,AVG(data_with_rownumber.D) AS median
From
(
Select ROW_NUMBER() OVER(PARTITION BY A.C ORDER BY A.M) AS seq,A.C as B,A.M as D
From
(Select course_enrolments.student,course_staff.course C,right(cast(semesters.year as varchar),2)||semesters.term,subjects.code,subjects.name,subjects.uoc,course_enrolments.mark M
From course_staff,semesters,courses,subjects,course_enrolments
where course_staff.staff=$1
And courses.id=course_staff.course
And courses.subject=subjects.id
And course_enrolments.mark is not Null
And course_enrolments.course=courses.id
And courses.semester=semesters.id
Group by course_enrolments.student,course_staff.course,semesters.year,semesters.term,subjects.code,subjects.name,subjects.uoc,course_enrolments.mark
Having count(course_enrolments.student)!=0
order by course_staff.course
) A) data_with_rownumber JOIN
(
Select E.C as F,COUNT(1) AS NumOfVal
From
(Select course_enrolments.student,course_staff.course C,right(cast(semesters.year as varchar),2)||semesters.term,subjects.code,subjects.name,subjects.uoc,course_enrolments.mark M
From course_staff,semesters,courses,subjects,course_enrolments
where course_staff.staff=$1
And courses.id=course_staff.course
And courses.subject=subjects.id
And course_enrolments.mark is not Null
And course_enrolments.course=courses.id
And courses.semester=semesters.id
Group by course_enrolments.student,course_staff.course,semesters.year,semesters.term,subjects.code,subjects.name,subjects.uoc,course_enrolments.mark
Having count(course_enrolments.student)!=0
order by course_staff.course
) E
Group by E.C) data_count
ON 
(data_count.F = data_with_rownumber.B
 AND (
  (data_count.NumOfVal % 2 = 0 AND data_with_rownumber.seq IN (data_count.NumOfVal / 2, (data_count.NumOfVal / 2) + 1))
  OR
  (data_count.NumOfVal % 2 = 1 AND data_with_rownumber.seq = 1 + data_count.NumOfVal / 2)))
Group by data_with_rownumber.B
) G
where course_staff.staff=$1
And courses.id=course_staff.course
And courses.subject=subjects.id
And course_enrolments.mark is not Null
And course_enrolments.course=courses.id
And courses.semester=semesters.id
And course_staff.course=G.H
Group by course_staff.course,semesters.year,semesters.term,subjects.code,subjects.name,subjects.uoc,G.median
Having count(course_enrolments.student)!=0
order by course_staff.course
loop
Return next N;
End loop;
Return;
End;

--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


--Q3:
create or replace function Q3_o(oid integer)
returns table(owner integer,member integer,name mediumstring)
as $$
with recursive r as
(select member,owner 
from orgunit_groups
where member=$1
union all select A.member,A.owner 
from orgunit_groups A
join r on r.member=A.owner)
select owner,member,orgunits.name 
from r,orgunits
where member=orgunits.id;
$$ language sql;

create or replace function Q3_1(oid integer,num_courses integer,min_score integer)
returns table(unswid integer,student_name text)
as $$
select people.unswid unswid,people.name
from Q3_o($1),people,courses,course_enrolments,subjects
where courses.subject=subjects.id
and subjects.offeredby=Q3_o.member
and courses.id=course_enrolments.course
and course_enrolments.student=people.id
group by people.unswid,people.name
having count(courses.id)>$2
and max(course_enrolments.mark)>=$3;
$$ language sql;

create or replace function Q3_2(oid integer,num_courses integer,min_score integer)
returns table(unswid integer,student_name text,course_records text,score integer)
as $$
select people.unswid,people.name,cast(subjects.code || ', ' || subjects.name || ', ' || semesters.name || ', ' || orgunits.name || ', ' || coalesce(cast(course_enrolments.mark as text),'null') as text),coalesce(course_enrolments.mark,0) score
from Q3_1($1,$2,$3),people,courses,course_enrolments,subjects,semesters,orgunits,Q3_o($1)
where courses.subject=subjects.id
and Q3_1.unswid=people.unswid
and courses.id=course_enrolments.course
and course_enrolments.student=people.id
and semesters.id=courses.semester
and orgunits.id=subjects.offeredby
and subjects.offeredby=Q3_o.member
order by people.unswid,score desc,courses.id asc;
$$ language sql;

create or replace function Q3_3(oid integer,num_courses integer,min_score integer)
returns table(unswid integer,student_name text,course_records text,R bigint)
as $$
select unswid,student_name,course_records, ROW_NUMBER() OVER (PARTITION BY unswid) AS R
from Q3_2($1,$2,$3)
;
$$ language sql;

drop type if exists CourseRecord cascade;
create type CourseRecord as (unswid integer, student_name text, course_records text);

create or replace function Q3(org_id integer, num_courses integer, min_score integer)
  returns setof CourseRecord
as $$
begin 
if $1 not in (select id from orgunits) then
raise exception'INVALID ORGID';
end if;
return query
select unswid,student_name,string_agg(course_records,chr(10))|| chr(10) 
from Q3_3($1,$2,$3)
where R<=5
group by unswid,student_name;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;
