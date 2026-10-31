select * from my_employees where department_id = 10;

update my_employees
set phone_number = '1.515.111.1111'
, email = 'FELLOMEZA@EXAMPLE.COM'
where employee_id = 200;
commit;
rollback;