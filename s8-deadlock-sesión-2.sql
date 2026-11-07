-- first 103 and then 102
-- deadlock example session 2
select * from my_employees where employee_id in (102, 103);
select * from my_employees where employee_id = 103 for update;
update my_employees set salary = salary + 1000 where employee_id = 103;

-- the same, but for 102
select * from my_employees where employee_id = 102 for update;
-- here, the deadlock will occur, because session 1 has already locked the row for employee_id = 102
update my_employees set salary = salary + 1000 where employee_id = 102;

-- let's see which session will be selected to kill (rollback) by the database engine, and which one will be able to continue

select 'hello world' as message from dual;


rollback;