select * from my_departments;

CREATE OR REPLACE TRIGGER check_department_manager
FOR INSERT OR UPDATE OF manager_id ON my_departments
COMPOUND TRIGGER
  TYPE manager_ids_t IS TABLE OF my_departments.manager_id%TYPE
    INDEX BY PLS_INTEGER;

  changed_managers manager_ids_t;
  manager_count    PLS_INTEGER := 0;

  AFTER EACH ROW IS
  BEGIN
    IF :NEW.manager_id IS NOT NULL THEN
      manager_count := manager_count + 1;
      changed_managers(manager_count) := :NEW.manager_id;
    END IF;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    department_count PLS_INTEGER;
  BEGIN
    FOR i IN 1 .. manager_count LOOP
      SELECT COUNT(*)
        INTO department_count
        FROM my_departments
       WHERE manager_id = changed_managers(i);

      IF department_count > 1 THEN
        RAISE_APPLICATION_ERROR(
          -20001,
          'A manager cannot manage more than one department'
        );
      END IF;
    END LOOP;
  END AFTER STATEMENT;
END check_department_manager;
/