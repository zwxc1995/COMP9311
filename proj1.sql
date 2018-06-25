-- COMP9311 18s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: 
create or replace view Q1(unswid, name)
as
Select people.unswid,people.name 
From people,students,course_enrolments
Where students.id=people.id
And course_enrolments.student=people.id
And students.stype='intl'
And course_enrolments.mark>=85
Group by people.unswid, people.name
Having count(course_enrolments.course)>20 
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q2: 
create or replace view Q2(unswid, name)
as
Select rooms.unswid,rooms.longname
From rooms,buildings,room_types
Where rooms.rtype=room_types.id
And rooms.building=buildings.id
And rooms.capacity>=20
And room_types.description='Meeting Room'
And buildings.name='Computer Science Building'
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q3: 
create or replace view Q3(unswid, name)
as
Select people.unswid,people.name
From people,course_staff
Where course_staff.course in(
			Select course_enrolments.course
			From course_enrolments,people
			Where people.name='Stefan Bilek'
			And course_enrolments.student=people.id)
And people.id=course_staff.staff
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q4:
create or replace view Q4(unswid, name)
as
Select Distinct people.unswid,people.name
From people,subjects,course_enrolments,courses
Where course_enrolments.student=people.id
And course_enrolments.course=courses.id
And courses.subject=subjects.id
And subjects.code='COMP3331'
Except
Select Distinct people.unswid,people.name
From people,subjects,course_enrolments,courses
Where course_enrolments.student=people.id
And course_enrolments.course=courses.id
And courses.subject=subjects.id
And subjects.code='COMP3231'
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q5: 
create or replace view Q5a(num)
as
Select count(DISTINCT program_enrolments.student) as num
From program_enrolments,stream_enrolments,streams,semesters,students
Where streams.name='Chemistry'
And semesters.id=program_enrolments.semester
And semesters.year='2011'
And semesters.term='S1'
And streams.id=stream_enrolments.stream
And stream_enrolments.partof=program_enrolments.id
And program_enrolments.student=students.id
And students.stype='local'
--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q5: 
create or replace view Q5b(num)
as
Select count(DISTINCT program_enrolments.student) as num
From program_enrolments,students,orgunits,programs,semesters
Where students.stype='intl'
And program_enrolments.student=students.id
And orgunits.longname='School of Computer Science and Engineering'
And orgunits.id=programs.offeredby
And programs.id=program_enrolments.program
And semesters.id=program_enrolments.semester
And semesters.year='2011'
And semesters.term='S1'
--... SQL statements, possibly using other views/functions defined by you ...
;


-- Q6:
create or replace function
	Q6(text) returns text
as
$$
Select subjects.code||' '||subjects.name||' '||subjects.uoc 
From subjects
Where subjects.code =$1
--... SQL statements, possibly using other views/functions defined by you ...
$$ language sql;



-- Q7: 
create or replace view Q7(code, name)
as
Select programs.code,programs.name
From programs,
(Select program_enrolments.program pro,count(program_enrolments.student) c1
From program_enrolments,students
Where program_enrolments.student=students.id
And students.stype='intl'
Group by pro) p1,
(Select program_enrolments.program pro,count(program_enrolments.student) c2
From program_enrolments,students
Where program_enrolments.student=students.id
Group by pro) p2
Where programs.id=p1.pro
And programs.id=p2.pro
And p1.c1*1.0/p2.c2>0.5
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q8:
create or replace view Q8(code, name, semester)
as
Select subjects.code,subjects.name,semesters.name
From subjects,semesters,courses,
(Select courses.id C3,AVG(course_enrolments.mark) A2
From courses,course_enrolments,(Select MAX(C1.A1) M2
     From (Select courses.id C2,AVG(course_enrolments.mark) A1
           From courses,course_enrolments
           Where course_enrolments.mark is not null
           And courses.id=course_enrolments.course
           Group by courses.id
           Having count(courses.id)>15) C1)M1
Where courses.id=course_enrolments.course
Group by courses.id,M1.M2
Having AVG(course_enrolments.mark)=M1.M2)R
Where courses.subject=subjects.id
And R.C3=courses.id
And courses.semester=semesters.id
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q9:
create or replace view Q9(name, school, email, starting, num_subjects)
as
Select people.name,orgunits.longname,people.email,affiliations.starting,count(DISTINCT subjects.code) as num_subjects
From people,orgunits,affiliations,staff_roles,orgunit_types,subjects,courses,course_staff
Where staff_roles.name='Head of School'
And staff_roles.id=affiliations.role
And affiliations.ending is null
And affiliations.isprimary='t'
And orgunit_types.name='School'
And orgunit_types.id=orgunits.utype
And orgunits.id=affiliations.orgunit
And affiliations.staff=course_staff.staff
And course_staff.course=courses.id
And courses.subject=subjects.id
And affiliations.staff=people.id
Group by people.name,orgunits.longname,people.email,affiliations.starting
Having count(DISTINCT subjects.code)>0
--... SQL statements, possibly using other views/functions defined by you ...
;



-- Q10:
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)
as
Select  DISTINCT subjects.code,subjects.name,right(cast(semesters.year as varchar),2),coalesce(round(G.C2*1.0/F.C1,2),0.00) as s1_HD_rate,coalesce(round(I.C4*1.0/H.C3,2),0.00) as s2_HD_rate
From subjects,semesters,courses,
(Select DISTINCT subjects.code O1,subjects.id,right(cast(semesters.year as varchar),2) as year,count(course_enrolments.student) C1,semesters.term as T1
From subjects,semesters,courses,course_enrolments,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And course_enrolments.course=courses.id
And course_enrolments.mark>=0
And semesters.term='S1'
Group by  subjects.code,subjects.id,year,T1
Order by subjects.code) F,
(Select L1.O2,L1.year,L2.C2,L1.T2
From
(Select DISTINCT subjects.code O2,subjects.id,right(cast(semesters.year as varchar),2) as year,semesters.term as T2
From subjects,semesters,courses,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And semesters.term='S1'
Group by  subjects.code,subjects.id,year,T2
Order by subjects.code)L1
Left join(
Select DISTINCT subjects.code O2,subjects.id,right(cast(semesters.year as varchar),2) as year,count(course_enrolments.student) C2,semesters.term as T2
From subjects,semesters,courses,course_enrolments,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And course_enrolments.course=courses.id
And course_enrolments.mark>=85
And semesters.term='S1'
Group by  subjects.code,subjects.id,year,T2
Order by subjects.code)L2
On L1.O2=L2.O2
And L1.year=L2.year) G,
(Select DISTINCT subjects.code O3,subjects.id,right(cast(semesters.year as varchar),2) as year,count(course_enrolments.student) C3,semesters.term as T3
From subjects,semesters,courses,course_enrolments,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And course_enrolments.course=courses.id
And course_enrolments.mark>=0
And semesters.term='S2'
Group by  subjects.code,subjects.id,year,T3
Order by subjects.code) H,
(Select L1.O4,L1.year,L2.C4,L1.T4
From
(Select DISTINCT subjects.code O4,subjects.id,right(cast(semesters.year as varchar),2) as year,semesters.term as T4
From subjects,semesters,courses,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And semesters.term='S2'
Group by  subjects.code,subjects.id,year,T4
Order by subjects.code)L1
Left join(
Select DISTINCT subjects.code O4,subjects.id,right(cast(semesters.year as varchar),2) as year,count(course_enrolments.student) C4,semesters.term as T4
From subjects,semesters,courses,course_enrolments,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And course_enrolments.course=courses.id
And course_enrolments.mark>=85
And semesters.term='S2'
Group by  subjects.code,subjects.id,year,T4
Order by subjects.code)L2
On L1.O4=L2.O4
And L1.year=L2.year) I,
(Select A.B D,count(*)
From
(Select DISTINCT subjects.id B,right(cast(semesters.year as varchar),2) as year,semesters.term
From subjects,semesters,courses,course_enrolments
Where subjects.id=courses.subject
And courses.id=course_enrolments.course
And courses.semester=semesters.id
And subjects.code like 'COMP93%'
And semesters.year>=2003
And semesters.year<=2012) A
Group by A.B
Having count(*)>=20)C
Where C.D=subjects.id
And semesters.year>=2003
And semesters.year<=2012
And subjects.id=courses.subject
And courses.semester=semesters.id
And subjects.code=F.O1
And subjects.code=G.O2
And subjects.code=H.O3
And subjects.code=I.O4
And F.O1=G.O2
And H.O3=I.O4
And F.year=G.year
And right(cast(semesters.year as varchar),2)=F.year
And H.year=I.year
And right(cast(semesters.year as varchar),2)=H.year
Group by  subjects.code,subjects.name,right(cast(semesters.year as varchar),2),s1_HD_rate,s2_HD_rate
Order by subjects.code
--... SQL statements, possibly using other views/functions defined by you ...
;
