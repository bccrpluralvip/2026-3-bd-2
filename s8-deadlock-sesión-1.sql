-- first 102 and then 103
-- deadlock example session 1

select * from my_employees where employee_id in (102, 103);


select * from my_employees where employee_id = 102 for update;
update my_employees set salary = salary + 1000 where employee_id = 102;

-- the same for record 103
select * from my_employees where employee_id = 103 for update;
-- here, the deadlock will occur, because session 2 has already locked the row for employee_id = 103
update my_employees set salary = salary + 1000 where employee_id = 103;

-- let's see which session will be selected to kill (rollback) by the database engine, and which one will be able to continue

select * from my_employees where employee_id = 103;

select 'hello world' as message from dual;

rollback;