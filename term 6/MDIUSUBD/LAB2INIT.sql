
DELETE FROM STUDENTS;
DELETE FROM GROUPS;

INSERT INTO GROUPS (NAME, C_VAL) VALUES ('953501', 0);
INSERT INTO GROUPS (NAME, C_VAL) VALUES ('953505', 0);

INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Vlad', 2);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Kirill', 2);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Fedjaz', 2);
INSERT INTO STUDENTS (NAME, GROUP_ID) VALUES ('Saharok', 1);

SELECT * FROM STUDENTS;
SELECT * FROM GROUPS;