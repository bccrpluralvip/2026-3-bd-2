SET SERVEROUTPUT ON;

select * from admin.my_employee_history;
update my_employees
   set salary = salary * 1.1
 where employee_id in (198, 200);

 update my_employees
   set salary = salary * 5
 where employee_id = 202;