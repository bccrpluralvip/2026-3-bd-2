-- Run this setup script while connected as ADMIN.
CREATE TABLE my_employee_history (
  history_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_time  TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  employee_id NUMBER,
  event_type  VARCHAR2(30) NOT NULL,
  message_text VARCHAR2(1000) NOT NULL
);

CREATE ROLE my_employee_history_rw;

GRANT SELECT, INSERT
  ON my_employee_history
  TO my_employee_history_rw;

GRANT my_employee_history_rw TO usersanpedro25;

-- Stored trigger code requires a direct object grant; role grants do not apply.
GRANT INSERT
  ON my_employee_history
  TO usersanpedro25;
