SET SERVEROUTPUT ON;
/*CREATE SEQUENCE students_id_sequence
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;
CREATE SEQUENCE groups_id_sequence
  MINVALUE 1
  MAXVALUE 999999999999999999999999999
  START WITH 1
  INCREMENT BY 1
  CACHE 20;
CREATE TABLE GROUPS (ID NUMBER UNIQUE NOT NULL, NAME VARCHAR2(100) NOT NULL, C_VAL NUMBER NOT NULL);
CREATE TABLE STUDENTS (ID NUMBER UNIQUE NOT NULL, NAME VARCHAR2(100) NOT NULL, GROUP_ID NUMBER REFERENCES Groups(ID));
/*/
/*2 */
CREATE OR REPLACE TRIGGER check_unique_id_group
BEFORE INSERT OR UPDATE OF ID ON GROUPS
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    notUniqueCount NUMBER;
    notUniqueGroupIDException EXCEPTION;
    PRAGMA EXCEPTION_INIT(notUniqueGroupIDException, -20000);
BEGIN
    SELECT COUNT(*) INTO notUniqueCount FROM GROUPS WHERE ID =:new.ID;
    IF notUniqueCount != 0 THEN
        RAISE notUniqueGroupIDException;
    END IF;
END;
/
CREATE OR REPLACE TRIGGER check_unique_id_student
BEFORE INSERT OR UPDATE OF ID ON STUDENTS
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    notUniqueCount NUMBER;
    notUniqueStudentIDException EXCEPTION;
    PRAGMA EXCEPTION_INIT(notUniqueStudentIDException, -20001);
BEGIN
    SELECT COUNT(*) INTO notUniqueCount FROM STUDENTS WHERE ID =:new.ID;
    IF notUniqueCount != 0 THEN
        RAISE notUniqueStudentIDException;
    END IF;
END;
/
CREATE OR REPLACE TRIGGER check_unique_groupname
BEFORE INSERT OR UPDATE OF NAME ON GROUPS
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    sameGroupsCount NUMBER;
    notUniqueGroupnameException EXCEPTION;
    PRAGMA EXCEPTION_INIT(notUniqueGroupnameException, -20002);
BEGIN
    SELECT COUNT(*) INTO sameGroupsCount  FROM Groups WHERE NAME = :new.NAME;
    IF sameGroupsCount != 0 THEN
        RAISE notUniqueGroupnameException;
    END IF;
END;
/
CREATE OR REPLACE TRIGGER increment_group_id
BEFORE INSERT ON GROUPS
FOR EACH ROW
FOLLOWS check_unique_groupname
BEGIN
    SELECT groups_id_sequence.nextval INTO :new.ID FROM GROUPS;
END;
/

CREATE OR REPLACE TRIGGER increment_student_id
BEFORE INSERT ON STUDENTS
FOR EACH ROW
BEGIN
    SELECT students_id_sequence.nextval into :new.ID FROM STUDENTS;
END;
/
/* 3*/

CREATE OR REPLACE TRIGGER cascade_group_delete
BEFORE DELETE ON GROUPS
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    DELETE FROM STUDENTS WHERE GROUP_ID=:old.ID;
    COMMIT;
END;
/

/* 4 */
/*CREATE TABLE JOURNAL (TIME TIMESTAMP NOT NULL, STATEMENT VARCHAR2(100) NOT NULL, ID_NEW NUMBER, ID_OLD NUMBER, NAME VARCHAR2(100), GROUP_ID NUMBER);*/

CREATE OR REPLACE TRIGGER logging
AFTER INSERT OR DELETE OR UPDATE ON STUDENTS
FOR EACH ROW
BEGIN
    CASE
    WHEN INSERTING THEN
        INSERT INTO JOURNAL VALUES (SYSTIMESTAMP, 'INSERT', :NEW.ID, NULL, :NEW.NAME, :NEW.GROUP_ID);
    WHEN UPDATING THEN
        INSERT INTO JOURNAL VALUES (SYSTIMESTAMP, 'UPDATE', :NEW.ID, :OLD.ID, :OLD.NAME, :OLD.GROUP_ID);
    WHEN DELETING THEN
        INSERT INTO JOURNAL VALUES (SYSTIMESTAMP, 'DELETE', NULL, :OLD.ID, :OLD.NAME, :OLD.GROUP_ID);
    END CASE;
END;
/
/* 5 */
CREATE OR REPLACE PROCEDURE restore(time IN TIMESTAMP)
IS
    CURSOR selected_logs IS
    SELECT * FROM JOURNAL
    WHERE TIME >= time
    ORDER BY TIME DESC;
BEGIN
    FOR current_log IN selected_logs
    LOOP
        CASE
            WHEN current_log.STATEMENT='INSERT' THEN
                DELETE FROM STUDENTS WHERE ID=current_log.ID_NEW;
            WHEN current_log.STATEMENT='UPDATE' THEN
                UPDATE STUDENTS SET ID=current_log.ID_OLD, NAME= current_log.NAME, GROUP_ID=current_log.GROUP_ID WHERE ID=current_log.ID_NEW;
            WHEN current_log.STATEMENT='DELETE' THEN
                INSERT INTO STUDENTS VALUES (current_log.ID_OLD, current_log.NAME, current_log.GROUP_ID);
        END CASE;
        DELETE FROM JOURNAL WHERE TIME = current_log.TIME;
    END LOOP;
END restore;
/
CREATE OR REPLACE PROCEDURE restore_by_offset(offset IN INTERVAL DAY TO SECOND)
IS
BEGIN
    restore(LOCALTIMESTAMP - offset);
END restore_by_offset;
/

/* 6. */
CREATE OR REPLACE TRIGGER students_change
AFTER INSERT OR DELETE OR UPDATE ON STUDENTS
FOR EACH ROW
DECLARE
rowcount NUMBER;
BEGIN
    CASE
        WHEN INSERTING THEN
            UPDATE GROUPS SET C_VAL=C_VAL+1 WHERE ID = :new.GROUP_ID;
        WHEN UPDATING THEN 
            UPDATE GROUPS SET C_VAL=C_VAL+1 WHERE ID = :new.GROUP_ID;
            UPDATE GROUPS SET C_VAL=C_VAL-1 WHERE ID = :old.GROUP_ID;
        WHEN DELETING THEN
            UPDATE GROUPS SET C_VAL=C_VAL-1 WHERE ID = :old.GROUP_ID;
    END CASE;
END;