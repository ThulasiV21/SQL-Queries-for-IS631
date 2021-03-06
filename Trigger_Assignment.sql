-- Adding columns to People table
IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name      = N'tt347_Total_Salary'
      AND Object_ID = Object_ID(N'PEOPLE'))
BEGIN
      ALTER TABLE PEOPLE ADD tt347_Total_Salary money NULL
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name      = N'tt347_Average_Salary'
      AND Object_ID = Object_ID(N'PEOPLE'))
BEGIN
      ALTER TABLE PEOPLE ADD tt347_Average_Salary money NULL
END
GO

-- Populate tt347_Total_Salary in People Table
UPDATE People 
SET tt347_Total_Salary = sa.Total_Salary
FROM ( SELECT s.playerID, SUM(s.salary) AS Total_Salary FROM Salaries s GROUP BY s.playerID
) AS sa
WHERE People.playerID = sa.playerID

--Populate tt347_Average_Salary in People Table
UPDATE People 
SET tt347_Average_Salary = sa.Avg_Salary
FROM ( SELECT s.playerID, AVG(s.salary) AS Avg_Salary FROM Salaries s GROUP BY s.playerID
) AS sa
WHERE People.playerID = sa.playerID

-- Check if the Trigger already exists
IF EXISTS (
    SELECT *
    FROM sys.objects
    WHERE [type] = 'TR' AND [name] = 'tt347_Salary'
    )
    DROP TRIGGER tt347_Salary;
GO

-- Create Trigger
CREATE TRIGGER tt347_Salary ON Salaries
AFTER UPDATE
    , INSERT
    , DELETE
AS
BEGIN
    IF EXISTS (
            SELECT *
            FROM inserted
            )
        AND EXISTS (
            SELECT *
            FROM deleted
            )
    BEGIN
        UPDATE People
        SET tt347_Total_Salary = (tt347_Total_Salary - d.salary + i.salary)
        FROM deleted d
            , inserted i
        WHERE People.playerID = d.playerID
            AND People.playerID = i.playerID;

        UPDATE People
        SET tt347_Average_Salary = (Sal.Average_Salary)
        FROM (
            SELECT s.playerID
                , AVG(s.salary) AS Average_Salary
            FROM Salaries s
                , inserted i
            WHERE s.playerID = i.playerID
            GROUP BY s.playerID
            ) Sal
        WHERE People.playerID = Sal.playerID
    END

    IF EXISTS (
            SELECT *
            FROM inserted
            )
        AND NOT EXISTS (
            SELECT *
            FROM deleted
            )
    BEGIN
        UPDATE People
        SET tt347_Total_Salary = (tt347_Total_Salary + i.salary)
        FROM inserted i
        WHERE People.playerID = i.playerID;

        UPDATE People
        SET tt347_Average_Salary = (Sal.Average_Salary)
        FROM (
            SELECT s.playerID
                , AVG(s.salary) AS Average_Salary
            FROM Salaries s
                , inserted i
            WHERE s.playerID = i.playerID
            GROUP BY s.playerID
            ) Sal
        WHERE People.playerID = Sal.playerID
    END

    IF NOT EXISTS (
            SELECT *
            FROM inserted
            )
        AND EXISTS (
            SELECT *
            FROM deleted
            )
    BEGIN
        UPDATE People
        SET tt347_Total_Salary = (tt347_Total_Salary - d.salary)
        FROM deleted d
        WHERE People.playerID = d.playerID;

        UPDATE People
        SET tt347_Average_Salary = (Sal.Average_Salary)
        FROM (
            SELECT s.playerID
                , AVG(s.salary) AS Average_Salary
            FROM Salaries s
                , deleted d
            WHERE s.playerID = d.playerID
            GROUP BY s.playerID
            ) Sal
        WHERE People.playerID = Sal.playerID
    END
END
GO

-- Setting up data in People to test trigger
INSERT INTO People VALUES ('doejane01',1865,9,14,'USA','NY','Piermont',1937,5,18,'USA','NY','New York','Doc','Leitner','George Aloysius',185,71,'R','R',1887-08-10,1887-09-17,'leitd102','leitndo01', null, null, null, null, null)
 
DELETE FROM Salaries WHERE playerID='doejane01'
update people
set tt347_Total_Salary = 0
update people
set tt347_Average_Salary = 0
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID = 'doejane01';

-- Trigger test for INSERT
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID = 'doejane01';
INSERT INTO Salaries VALUES ('1992', 'NYA', 'AL', 'doejane01', 3250000.00, null, null);
INSERT INTO Salaries VALUES ('1993', 'NYA', 'AL', 'doejane01', 4250000.00, null, null);
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID = 'doejane01';
 
-- Trigger test for UPDATE
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID='doejane01';
SELECT * FROM Salaries WHERE playerID='doejane01';
UPDATE Salaries SET salary=403250.00 WHERE playerID='doejane01' and yearid = 1992;
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID='doejane01';
 
-- trigger test for DELETE
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID='doejane01';
SELECT * FROM Salaries WHERE playerID='doejane01';
DELETE FROM Salaries WHERE playerID='doejane01' and yearid = 1992;
SELECT p.playerID, p.tt347_Total_Salary, p.tt347_Average_Salary FROM People p WHERE p.playerID='doejane01';