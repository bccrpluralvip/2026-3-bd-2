-- Recovery Stage 1
-- verify that the database has the setting to enable recycle bin
SELECT name, value FROM v$parameter WHERE name = 'recyclebin';
-- create a table from my_jobs and drop it to verify that the recycle bin is working
CREATE TABLE test_table AS SELECT * FROM my_jobs;
DROP TABLE test_table;
-- verify that the table is in the recycle bin
SELECT object_name, original_name, type FROM recyclebin;
-- restore the table from the recycle bin
FLASHBACK TABLE test_table TO BEFORE DROP;
-- verify that the table has been restored and has the same number of rows as the original table
SELECT COUNT(*) FROM test_table;
SELECT COUNT(*) FROM my_jobs;

-- stage 2:  the object is dropped and when tried to restore, an object with the same name already exists in the database.  The table is restored with a new name and the original name is lost.
drop table test_table;
select object_name, original_name, type from recyclebin;
create table test_table as select * from my_employees;
-- try to restore the table from the recycle bin but with a different name, since the original already exists
FLASHBACK TABLE test_table TO BEFORE DROP RENAME TO test_table_restored;
-- verify that the table has been restored with a new name and has the same number of rows as the original table
SELECT COUNT(*) FROM test_table_restored;
SELECT COUNT(*) FROM my_jobs;

-- stage 3:  the object is dropped and then i create a new object with the same name, which will be also dropped.  i need to know which object to restore from the recycle bin, since there are two objects with the same name in the recycle bin.  I will use the original_name column to identify which object to restore.
drop table test_table_restored;
create table test_table_restored as select * from test_table;
drop table test_table_restored;
-- verify that there are two objects with the same name in the recycle bin
SELECT object_name, original_name, type FROM recyclebin;
-- try to distinguish between the two objects in the recycle bin by using the original_name column
SELECT object_name, original_name, type FROM recyclebin WHERE original_name = 'TEST_TABLE_RESTORED';
-- try to query the data of the first deleted object in the recycle bin by using the original_name column
SELECT * FROM "BIN$YD4V76PsKg/gYxRZAAqqXg==$0" WHERE ROWNUM <= 10;
SELECT * FROM "BIN$YD4V76PxKg/gYxRZAAqqXg==$0" WHERE ROWNUM <= 10;
-- restore the first deleted object in the recycle bin by using  a brand new name, since the original name is already taken by the second deleted object in the recycle bin
-- restore the first deleted object in the recycle bin by using the original_name column
FLASHBACK TABLE "BIN$YD4V76PxKg/gYxRZAAqqXg==$0" TO BEFORE DROP RENAME TO test_table_restored_my_employees;
-- restore the other deleted object in the recycle bin by using the original_name column
FLASHBACK TABLE "BIN$YD4V76PsKg/gYxRZAAqqXg==$0" TO BEFORE DROP RENAME TO test_table_restored_my_jobs;
-- verify the recycle bin is empty
SELECT object_name, original_name, type FROM recyclebin;

-- awesome... let's try stage 4:  the all-mighty it-will-never-happen-to-me scenario:  the terrifying delete without a where clause.  i will delete all the rows from my_jobs and then try to restore them from the recycle bin.  since the table is not dropped, it will not be in the recycle bin, but the rows will be in the undo tablespace.  i will use flashback query to restore the rows.
DELETE FROM my_jobs;
commit;
-- verify that the table is empty
SELECT COUNT(*) FROM my_jobs;
-- search for the table on the recycle bin, it should not be there since it was not dropped
SELECT object_name, original_name, type FROM recyclebin;
-- use flashback query to restore the rows from the undo tablespace
SELECT * FROM my_jobs AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '4' MINUTE);
-- restore the rows from the flashback query into a new table
CREATE TABLE my_jobs_restored_v2 AS SELECT * FROM my_jobs AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '6' MINUTE);
-- insert the rows from the restored table back into the original table
INSERT INTO my_jobs SELECT * FROM my_jobs_restored_v2;
commit;
-- verify that the rows have been restored
SELECT COUNT(*) FROM my_jobs;

-- stage 5:  the all-mighty it-will-never-happen-to-me scenario:  the terrifying update without a where clause.  
UPDATE my_jobs SET job_title = 'Updated Job Title';
commit;
-- verify that the table has been updated
SELECT COUNT(*) FROM my_jobs WHERE job_title = 'Updated Job Title';
-- use flashback query to view the previous state of the table before the update
SELECT * FROM my_jobs AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '4' MINUTE);
-- restore the previous state of the table before the update into a new table
CREATE TABLE my_jobs_restored_v3 AS SELECT * FROM my_jobs AS OF TIMESTAMP (SYSTIMESTAMP - INTERVAL '6' MINUTE);
-- query the restored table to verify that it has the previous state of the table before the update
SELECT COUNT(*) FROM my_jobs_restored_v3 WHERE job_title != 'Updated Job Title';
-- update the original table with the previous state of the table before the update.  do not delete the rows that were updated, just update them back to their previous state.
UPDATE my_jobs j SET job_title = (SELECT job_title FROM my_jobs_restored_v3 r WHERE j.job_id = r.job_id);
-- verify that the table has been restored to its previous state before the update
SELECT COUNT(*) FROM my_jobs WHERE job_title != 'Updated Job Title';
commit;
select * from my_jobs;