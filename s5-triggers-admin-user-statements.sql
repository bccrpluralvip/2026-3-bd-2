CREATE ROLE my_employee_history_rw;

CREATE TABLE my_employee_history (
  history_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_time   TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
  employee_id  NUMBER,
  event_type   VARCHAR2(30) NOT NULL,
  message_text VARCHAR2(1000) NOT NULL
);

GRANT SELECT, INSERT
  ON my_employee_history
  TO my_employee_history_rw;

GRANT my_employee_history_rw TO usersanpedro25;

-- The trigger needs a direct grant; privileges through roles
-- are not available to stored trigger code.
GRANT INSERT
  ON my_employee_history
  TO usersanpedro25;