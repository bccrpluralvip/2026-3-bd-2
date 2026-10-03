SELECT
    x.employee_id,
    x.full_name,
    x.department_id,
    x.department_name,
    x.job_id,
    x.job_title,
    x.assignment_start_date,
    x.assignment_end_date
FROM (
    -- current assignment
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS full_name,
        d.department_id,
        d.department_name,
        j.job_id,
        j.job_title,
        e.hire_date AS assignment_start_date,
        NULL AS assignment_end_date
    FROM employees e
    JOIN departments d
      ON d.department_id = e.department_id
    JOIN jobs j
      ON j.job_id = e.job_id
    WHERE e.employee_id = 200
    UNION ALL

    -- historical assignments
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name AS full_name,
        d.department_id,
        d.department_name,
        jh.job_id,
        j.job_title,
        jh.start_date AS assignment_start_date,
        jh.end_date AS assignment_end_date
    FROM job_history jh
    JOIN employees e
      ON e.employee_id = jh.employee_id
    JOIN departments d
      ON d.department_id = jh.department_id
    JOIN jobs j
      ON j.job_id = jh.job_id
    WHERE e.employee_id = 200
) x
WHERE x.assignment_start_date <= '01-JAN-24'
  AND NVL(x.assignment_end_date, DATE '9999-12-31') >= '01-JAN-24'
ORDER BY x.assignment_start_date;

CREATE OR REPLACE PROCEDURE p_cursor_demo (
  p_department_id     IN my_employees.department_id%TYPE,
  p_conversion_factor IN NUMBER
) AS
  CURSOR employee_cursor (
    cp_department_id     IN my_employees.department_id%TYPE,
    cp_conversion_factor IN NUMBER
  ) IS
    SELECT
      e.employee_id,
      e.last_name || ', ' || e.first_name AS full_name,
      e.email,
      e.phone_number,
      d.department_name,
      e.hire_date,
      TRUNC(MONTHS_BETWEEN(SYSDATE, e.hire_date) / 12) AS years_of_service,
      e.salary,
      e.salary * cp_conversion_factor AS converted_salary
    FROM my_employees e
    JOIN my_departments d
      ON d.department_id = e.department_id
    WHERE e.department_id = cp_department_id
    ORDER BY e.employee_id;
  CURSOR job_history_cursor (
    cp_employee_id IN my_employees.employee_id%TYPE
  ) IS
    SELECT start_date, end_date, elapsed_months, job_title
    FROM (
      SELECT
        jh.start_date,
        jh.end_date,
        TRUNC(MONTHS_BETWEEN(jh.end_date, jh.start_date)) AS elapsed_months,
        j.job_title,
        ROW_NUMBER() OVER (
          ORDER BY jh.start_date DESC, jh.end_date DESC
        ) AS job_rank
      FROM my_job_history jh
      JOIN my_jobs j
        ON j.job_id = jh.job_id
      WHERE jh.employee_id = cp_employee_id
    )
    WHERE job_rank <= 2
    ORDER BY start_date DESC, end_date DESC;
  job_found BOOLEAN;
BEGIN
  DBMS_OUTPUT.PUT_LINE(
    'EMPLOYEE_ID | FULL_NAME | EMAIL | PHONE_NUMBER | DEPARTMENT_NAME | HIRE_DATE | YEARS_OF_SERVICE | SALARY | CONVERTED_SALARY'
  );

  FOR employee_rec IN employee_cursor(p_department_id, p_conversion_factor) LOOP
    DBMS_OUTPUT.PUT_LINE(
      employee_rec.employee_id || ' | ' ||
      employee_rec.full_name || ' | ' ||
      NVL(employee_rec.email, '-') || ' | ' ||
      NVL(employee_rec.phone_number, '-') || ' | ' ||
      employee_rec.department_name || ' | ' ||
      TO_CHAR(employee_rec.hire_date, 'YYYY-MM-DD') || ' | ' ||
      employee_rec.years_of_service || ' | ' ||
      employee_rec.salary || ' | ' ||
      employee_rec.converted_salary
    );

    job_found := FALSE;
    FOR job_rec IN job_history_cursor(employee_rec.employee_id) LOOP
      IF NOT job_found THEN
        DBMS_OUTPUT.PUT_LINE('  START_DATE | END_DATE | ELAPSED_MONTHS | JOB_TITLE');
        job_found := TRUE;
      END IF;
      DBMS_OUTPUT.PUT_LINE(
        '  ' || TO_CHAR(job_rec.start_date, 'YYYY-MM-DD') || ' | ' ||
        TO_CHAR(job_rec.end_date, 'YYYY-MM-DD') || ' | ' ||
        job_rec.elapsed_months || ' | ' ||
        job_rec.job_title
      );
    END LOOP;
    IF NOT job_found THEN
      DBMS_OUTPUT.PUT_LINE('  No job history found.');
    END IF;
  END LOOP;
END p_cursor_demo;
/

SET SERVEROUTPUT ON;

BEGIN
    p_cursor_demo(p_department_id => 50, p_conversion_factor => 0.92);
END;
/

CREATE TABLE my_special_departments (
  department_id NUMBER(4) PRIMARY KEY,
  successfully_processed CHAR(1) DEFAULT 'N' NOT NULL
    CHECK (successfully_processed IN ('Y', 'N')),
  date_time_processed TIMESTAMP
);

INSERT INTO my_special_departments (department_id)
SELECT distinct d.department_id
FROM my_departments d
WHERE NOT EXISTS (
  SELECT 1
  FROM my_special_departments sd
  WHERE sd.department_id = d.department_id
);

CREATE OR REPLACE PROCEDURE p_process_my_special_departments AS
  c_conversion_factor CONSTANT NUMBER := 0.92;
  c_success_threshold CONSTANT NUMBER := 30;
  v_random_percent NUMBER;
  CURSOR department_cursor IS
    SELECT department_id
    FROM my_special_departments
    WHERE successfully_processed = 'N'
    ORDER BY department_id;
BEGIN
  FOR department_rec IN department_cursor LOOP
    v_random_percent := TRUNC(DBMS_RANDOM.VALUE(0, 100), 2);

    IF v_random_percent < c_success_threshold THEN
      p_cursor_demo(department_rec.department_id, c_conversion_factor);

      UPDATE my_special_departments
      SET successfully_processed = 'Y',
          date_time_processed = SYSTIMESTAMP
      WHERE department_id = department_rec.department_id;
      COMMIT;

      DBMS_OUTPUT.PUT_LINE(
        'Department ' || department_rec.department_id ||
        ' processed successfully (random ' ||
        TO_CHAR(v_random_percent, 'FM990D00') || '%).'
      );
    ELSE
      DBMS_OUTPUT.PUT_LINE(
        'Process for department ' || department_rec.department_id ||
        ' failed because random ' ||
        TO_CHAR(v_random_percent, 'FM990D00') ||
        '% is greater than or equal to the ' || c_success_threshold || '% threshold.'
      );
    END IF;
  END LOOP;
END p_process_my_special_departments;
/

SET SERVEROUTPUT ON;

BEGIN
  p_process_my_special_departments;
END;
/
