CREATE OR REPLACE TRIGGER t
  BEFORE INSERT OR UPDATE OF salary, department_id OR DELETE
  ON my_employees
  FOR EACH ROW
DECLARE
  v_max_sal_inc_perc my_parameters.parameter_value%TYPE;
  v_actual_sal_inc_perc NUMBER;
  v_message VARCHAR2(1000);

  PROCEDURE log_history(
    p_employee_id IN my_employees.employee_id%TYPE,
    p_event_type  IN VARCHAR2,
    p_message     IN VARCHAR2
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO admin.my_employee_history (
      employee_id,
      event_type,
      message_text
    )
    VALUES (
      p_employee_id,
      p_event_type,
      p_message
    );

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END log_history;
BEGIN
  IF INSERTING THEN
    v_message := 'Inserting employee ' || :NEW.employee_id ||
                 ', salary: ' || :NEW.salary;
    DBMS_OUTPUT.PUT_LINE(v_message);
    log_history(:NEW.employee_id, 'INSERT', v_message);

  ELSIF UPDATING('salary') THEN
    SELECT parameter_value
      INTO v_max_sal_inc_perc
      FROM my_parameters
     WHERE parameter_id = 'max_sal_inc_perc';

    IF :NEW.salary > :OLD.salary * (1 + v_max_sal_inc_perc / 100) THEN
      IF :OLD.salary = 0 THEN
        v_actual_sal_inc_perc := NULL;
      ELSE
        v_actual_sal_inc_perc :=
          ((:NEW.salary - :OLD.salary) / :OLD.salary) * 100;
      END IF;

      v_message :=
        'Salary change for employee ' || :NEW.employee_id ||
        ' from ' || :OLD.salary || ' to ' || :NEW.salary ||
        ' exceeds the maximum allowed because the increase is ' ||
        NVL(TO_CHAR(v_actual_sal_inc_perc) || '%',
            'undefined (old salary is zero)') ||
        ' and the maximum allowed is ' || v_max_sal_inc_perc || '%';

      log_history(:NEW.employee_id, 'REJECTED_SALARY_UPDATE', v_message);

      RAISE_APPLICATION_ERROR(-20001, v_message);
    END IF;

    v_message := 'Employee ' || :NEW.employee_id ||
                 ' salary changed from ' || :OLD.salary ||
                 ' to ' || :NEW.salary;
    DBMS_OUTPUT.PUT_LINE(v_message);
    log_history(:NEW.employee_id, 'UPDATE_SALARY', v_message);

  ELSIF UPDATING('department_id') THEN
    v_message := 'Employee ' || :NEW.employee_id ||
                 ' department changed from ' || :OLD.department_id ||
                 ' to ' || :NEW.department_id;
    DBMS_OUTPUT.PUT_LINE(v_message);
    log_history(:NEW.employee_id, 'UPDATE_DEPARTMENT', v_message);

  ELSIF DELETING THEN
    v_message := 'Deleting employee ' || :OLD.employee_id ||
                 ', salary: ' || :OLD.salary;
    DBMS_OUTPUT.PUT_LINE(v_message);
    log_history(:OLD.employee_id, 'DELETE', v_message);
  END IF;
END;
/