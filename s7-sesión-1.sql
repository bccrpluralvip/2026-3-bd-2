select * from my_employees where department_id = 10;

select email from my_employees 
where employee_id = 200
FOR UPDATE;

select phone_number from my_employees 
where employee_id = 200;

update my_employees
set phone_number = '1.515.333.3333'
, email = 'HELL@EXAMPLE.COM'
where employee_id = 200
and email = 'HELLOWORLD@EXAMPLE.COM'
and phone_number = '1.515.667.6666';
rollback;
commit;