-- comp9311 19T3 Project 1
--
-- MyMyUNSW Solutions


-- Q1:
create or replace view Q1(unswid, longname)
as
select distinct r.unswid, r.longname
from rooms r, room_facilities rf, facilities f
where r.id = rf.room and rf.facility = f.id and f.description = 'Air-conditioned'
;


-- Q2:
create or replace view Q2(unswid,name)
as
select p.unswid, p.name
from people p, staff s, course_staff cs 
where p.id = s.id and s.id = cs.staff 
and cs.course in (select ce.course 
                  from course_enrolments ce
                  where ce.student = (select p2.id 
                                   from people p2
                                   where p2.name = 'Hemma Margareta'))
;

-- Q3:
create or replace view enrolment_situation(unswid, name, id, course, semester, subject, code)
as
select distinct p.unswid, p.name, p.id, c.id, c.semester, s.id, s.code
from people p, students stu, course_enrolments ce, courses c, subjects s 
where p.id = stu.id and stu.id = ce.student and ce.course = c.id and c.subject = s.id 
and ce.mark >= 85 and stu.stype = 'intl' and (s.code = 'COMP9311' or s.code = 'COMP9024');

create or replace view Q3(unswid, name)
as
select distinct p.unswid, p.name 
from people p, enrolment_situation es1, enrolment_situation es2  
where p.id = es1.id and es1.id = es2.id and es1.semester = es2.semester and es1.code = 'COMP9311' and es2.code = 'COMP9024'
;

-- Q4:
create or replace view student_HD_number(student, num_HD) 
as 
select student, count(grade) 
from course_enrolments 
where grade = 'HD'
group by student;

create or replace view all_student(student) 
as 
select student
from course_enrolments 
where mark is not NULL
group by student

create or replace view Q4(num_student) 
as 
select count(s1.student)
from student_HD_number s1
where s1.num_HD > ((select count(ce1.grade)
                from course_enrolments ce1
                where ce1.grade = 'HD') / (select count(*) 
                                           from all_student))
;

--Q5:
create or replace view all_course(c_id, sub_id, sem_id, sub_code, sub_name, sem_name, mark) 
as 
select c.id, c.subject, c.semester, sub.code, sub.name, sem.name, ce.mark 
from semesters sem, courses c, subjects sub, course_enrolments ce
where sem.id = c.semester and c.subject = sub.id and c.id = ce.course 
;
create or replace view valid_course(id, max_mark)
as
select course, MAX(mark) 
from course_enrolments  
group by (course)
having count(mark) >= 20 
;
create or replace view min_every_semester(semester, lowest)
as
select ac.sem_id, MIN(vc.max_mark)
from all_course ac, valid_course vc
where ac.c_id = vc.id and ac.mark = vc.max_mark 
group by (ac.sem_id) 
;
create or replace view Q5(code, name, semester)
as
select sub.code, sub.name, s.name 
from valid_course v, courses c, subjects sub, semesters s, min_every_semester m  
where v.id = c.id and c.subject = sub.id and c.semester = s.id  and s.id = m.semester
and v.max_mark = m.lowest 
;

-- Q6:
create or replace view valid_student(id) 
as
(select distinct stu.id 
from students stu, program_enrolments pe, 
semesters sem, stream_enrolments se, streams s 
where stu.id = pe.student and pe.semester = sem.id 
and pe.id = se.partof and se.stream = s.id 
and s.name = 'Management' and sem.year = '2010' and sem.term = 'S1' and stu.stype = 'local' )
EXCEPT 
(select distinct stu.id 
from students stu, course_enrolments ce, 
courses c, subjects s, orgunits o  
where stu.id = ce.student and ce.course = c.id 
and c.subject = s.id and s.offeredby = o.id 
and o.name = 'Faculty of Engineering');

create or replace view Q6(num) 
as
select COUNT(id)
from valid_student
;

-- Q7:
create or replace view Q7(year, term, average_mark)
as
select sem.year, sem.term, AVG(ce.mark)::numeric(4,2)
from course_enrolments ce, courses c, semesters sem, subjects sub 
where ce.course = c.id and c.semester = sem.id and c.subject = sub.id 
and sub.name = 'Database Systems' and ce.mark is not NULL 
group by (sem.id) 
;


-- Q8:
create or replace view set_semester(id) 
as
select distinct sem.id 
from courses c  
join semesters sem on (c.semester = sem.id) 
join subjects sub on (c.subject = sub.id) 
where sub.code like 'COMP93%' 
and (sem.term = 'S1' or sem.term = 'S2')
and sem.year between 2004 and 2013
;

create or replace view comp93(subject, semester)  
as
select distinct c.subject, c.semester 
from courses c  
join semesters sem on (c.semester = sem.id) 
join subjects sub on (c.subject = sub.id) 
where sub.code like 'COMP93%' 
;

create or replace view set_subject(subject)  
as
select distinct a.subject 
from comp93 a 
where not exists (select * 
                  from set_semester b 
                  except 
                  (select c.semester  
                    from comp93 c 
                    where c.subject = a.subject))
;

create or replace view set_student_subject(id, subject)
as
select stu.id, c.subject 
from students stu
join course_enrolments ce on (stu.id = ce.student)  
join courses c on (ce.course = c.id)  
where ce.mark is not Null and ce.mark < 50 
;

create or replace view target_student(id)
as
select distinct a.id 
from set_student_subject a  
where not exists ((select b.subject  
                   from set_subject b)
                   except
                   (select distinct c.subject 
                   from set_student_subject c  
                   where c.id = a.id))
;
create or replace view Q8(zid, name)
as
select 'z'||p.unswid, p.name 
from people p, target_student ts 
where p.id = ts.id 
;




-- Q9:
-- condition 1:
create or replace view Q9_00(id)
as
select distinct stu.id
from students stu 
join program_enrolments pe on (stu.id = pe.student) 
join programs p on (pe.program = p.id) 
join program_degrees pd on (p.id = pd.program) 
where pd.abbrev = 'BSc' 
;

-- condition 2:
create or replace view Q9_01(id)
as
select distinct A.id  
from Q9_00 A 
join course_enrolments ce on (A.id = ce.student) 
join courses c on (ce.course = c.id)
join program_enrolments pe on (c.semester = pe.semester) 
join semesters sem on (pe.semester = sem.id) 
where sem.name = 'Sem2 2010' and ce.mark >= 50 
;

-- condition 3 :
create or replace view Q9_02(id, program, average_mark)
as
select pe.student, pe.program, AVG(ce.mark) 
from Q9_01 AB 
join program_enrolments pe on (AB.id = pe.student) 
join semesters s on (pe.semester = s.id) 
join courses c on (pe.semester = c.semester) 
join course_enrolments ce on (c.id = ce.course) 
where s.year < 2011 and pe.student = ce.student 
group by pe.id, pe.program 
;

create or replace view Q9_03(id)
as
select a.id  
from Q9_02 a 
where a.id not in (SELECT a.id 
                   from Q9_02 a 
                   where average_mark < 80)

;

-- condition 4 : 
create or replace view Q9_04(id, program, total_uoc)
as
select a.id, pe.program, SUM(sub.uoc)
from stu_third_condition a 
join program_enrolments pe on (a.id = pe.student) 
join semesters sem on (pe.semester = sem.id) 
join courses c on (pe.semester = c.semester) 
join course_enrolments ce on (c.id = ce.course) 
join subjects sub on (c.subject = sub.id) 
where sem.year < 2011 and ce.mark >= 50 and ce.student = pe.student 
group by a.id, pe.program 
;

create or replace view Q9_05(id) 
as 
select distinct a.id 
from Q9_04 a 
where a.id not in (select distinct a.id 
                   from Q9_04 a 
                   join programs p on (a.program = p.id)
                   where a.total_uoc < p.uoc)
;

create or replace view Q9(unswid, name)
as
select p.unswid, p.name 
from Q9_05 a  
join people p on (a.id = p.id)
;

-- Q10:
-- all Lecture Theatre 
create or replace view all_LT(id, unswid)
as
select r.id, r.unswid
from rooms r 
join room_types rt on (r.rtype = rt.id) 
where rt.description = 'Lecture Theatre' 
;

-- all classes 
create or replace view all_classes(id, room)
as
select distinct cls.id, cls.room 
from classes cls  
join courses c on (cls.course = c.id)
join semesters s on (c.semester = s.id) 
where s.year = 2011 and s.term = 'S1' 
and cls.room in (select distinct a.id 
                 from all_LT a) 
;

create or replace view all_combos(room_id, num_classes, rank)
as
select alt.id, count(alc.room) as num_classes, rank() over (order by count(alc.room) desc)
from all_LT alt  
left outer join all_classes alc on (alt.id = alc.room) 
group by alt.id 
;


create or replace view Q10(unswid, longname, num, rank)
as
select r.unswid, r.longname, ac.num_classes, ac.rank  
from rooms r
join all_combos ac on (r.id = ac.room_id)  
;
