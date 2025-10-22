-- Homework 3 - Group 1
-- Authors: Nada Mikky, Jaxon Fielding, Olivia Gottlieb
-- Description: Deliverable file, contains Stored Procedures, UDFs, and Triggers for MIS assignment
USE Homework3Group1;
GO

create or alter procedure procValidateUser
(@username nvarchar(320), @password nvarchar(100))
as
begin
	select AppUserID, FullName
	from AppUser
	where Email = @username and
		PasswordHash = CONVERT(VARBINARY(64), @password, 1)
end;
go
/*
execute procValidateUser
@username = 'mjordan@wvu.edu', 
@password = '0x01';

select AppUserID, FullName, email, PasswordHash
from AppUser
*/

-- Section I: stored procedures and user defined functions
/* =================================================================================
   1. As a student
   I would like to know all the course offerings for the current semester for a 
   particular course so that I can enroll in the offering that fits my schedule.
   DONE by NADA
================================================================================= */
CREATE OR ALTER PROCEDURE procFindCurrentSemesterCourseOfferingsForSpecifiedCourse
(
    @subjectCode NVARCHAR(10),
    @courseNumber NVARCHAR(10)
)
AS 
BEGIN
    SELECT C.SubjectCode,
           C.CourseNumber,
           CO.CRN,
           CO.CourseOfferingSemester,
           CO.CourseOfferingYear
    FROM Course C
    INNER JOIN CourseOffering CO
        ON C.CourseID = CO.CourseID
    WHERE C.SubjectCode = @subjectCode
      AND C.CourseNumber = @courseNumber
      AND CO.CourseOfferingYear = DATEPART(YEAR, SYSDATETIME())
      AND CO.CourseOfferingSemester = dbo.fnFindCurrentSemester();
END;
GO

-- Helper function to get the current semester based on month
CREATE OR ALTER FUNCTION fnFindCurrentSemester()
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @semester NVARCHAR(20);

    IF DATEPART(MONTH, SYSDATETIME()) IN (8, 9, 10, 11, 12)
        SET @semester = 'Fall';
    ELSE IF DATEPART(MONTH, SYSDATETIME()) IN (1, 2, 3, 4, 5)
        SET @semester = 'Spring';
    ELSE
        SET @semester = 'Summer';

    RETURN @semester;
END;
GO

/* -- Test for 1st user story: 
   -- Shows all MIST 460 offerings for the current semester.
 
 EXEC procFindCurrentSemesterCourseOfferingsForSpecifiedCourse 
       @subjectCode = 'MIST', 
       @courseNumber = '460';
*/


/* =================================================================================
   2. As a student
   I would like to know the highly recommended jobs from alums who were in my major 
   (name/email/industry/job title) so that I can contact the alums.
   DONE
   Improvment: give name of alum to be addressed
   - Ask student for level of recommendatoin they're looking for 
================================================================================= */
CREATE OR ALTER PROCEDURE dbo.procGetRecommendedJobsByMajor
    @Major NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT U.Email AS AlumEmail,
           J.JobDescription,
           J.Industry AS JobIndustry,
           RJ.RecommendationLevel
    FROM Alum A
    JOIN AppUser U ON A.AlumID = U.AppUserID
    JOIN AlumJob RJ ON A.AlumID = RJ.AlumID
    JOIN Job J ON RJ.JobID = J.JobID
    ORDER BY U.Email;
END;
GO

-- 2. Example test: Gives a list of alumnis (emails, jobPositions and recommendation level
-- EXEC dbo.procGetRecommendedJobsByMajor @Major = 'MIST';


/* =================================================================================
   3. As a student
   I would like to know all the prerequisites for a recommended course so that 
   I can plan my schedule for the next few semesters.
   DONE
================================================================================= */
CREATE OR ALTER PROCEDURE dbo.procFindPrerequisites
(
    @SubjectCode NVARCHAR(20),
    @CourseNumber NVARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON; -- avoids extra output and removes output messages saying "x rows affected'

    SELECT P.SubjectCode, 
           P.CourseNumber
    FROM Course C
    JOIN CoursePrerequisite CP ON CP.CourseID = C.CourseID
    JOIN Course P ON P.CourseID = CP.CoursePrequisiteID
    WHERE C.SubjectCode = @SubjectCode
      AND C.CourseNumber = @CourseNumber;
END;
GO

-- Example test:
-- EXEC dbo.procFindPrerequisites @SubjectCode = 'MIST', @CourseNumber = '452'

CREATE OR ALTER FUNCTION fnFindAllCoursesTakenByStudent
(
	--@StudentFullname nvarchar(100)
	@studentID int
)
returns table
as
return
	select /*A.FullName, R.RegistrationID, CRN, CO.CourseOfferingYear,*/ C.SubjectCode, C.CourseNumber
	from 
	/*AppUser A join Student S
		on A.AppUserID = S.StudentID
		join*/ Registration R
		--on R.StudentID = S.StudentID
		join RegistrationCourseOffering RCO
		on R.RegistrationID = RCO.RegistrationID
		join CourseOffering CO
		on RCO.CourseOfferingID = CO.CourseOfferingID
		join Course C
		on CO.CourseID = C.CourseID
		where R.StudentID = @studentID
		--where A.FullName = @StudentFullname --@fullname

/*
SELECT SubjectCode, CourseNumber
FROM fnFindAllCoursesTakenByStudent(1);
*/


/* =================================================================================
   4. As a student
   I would also like to know if I have taken all the prerequisites for a recommended course
   DONE BY Jaxon
   Improvement: replace left join with normal join to save space and for better logic
================================================================================= */
CREATE OR ALTER PROCEDURE dbo.procCheckIfStudentMeetsPrerequisites
  (
	@studentID int, @subjectCode nvarchar(10), @courseNumber nvarchar(10)
)
as
begin
	
	SELECT SubjectCode, CourseNumber 
	FROM fnFindCoursePrerequisites(@subjectCode, @courseNumber)
	EXCEPT
	SELECT SubjectCode, CourseNumber
	FROM fnFindAllCoursesTakenByStudent(@studentID);
		
end;


-- Example test: Checks if you have completed prerequisites for specified course
-- EXEC dbo.procCheckIfStudentMeetsPrerequisites @StudentID = 1, @SubjectCode = 'MIST', @CourseNumber = '460'


/* =================================================================================
   5. As a student
   I want recommendations for courses
   * that I have not taken
   * that were taken by other students who completed at least two of the same courses as I have taken
   * where both the other student and I gave good reviews
   DONE BY Olivia
================================================================================= */
CREATE OR ALTER PROCEDURE dbo.procRecommendCourses
(
    @StudentID CHAR
)
AS
BEGIN
    DECLARE @GoodRating INT = 4;
    SET NOCOUNT ON;

    -- Courses the student has completed with good ratings
    WITH StudentCourses AS (
        SELECT rco.CourseOfferingID, co.CourseID
        FROM RegistrationCourseOffering rco
        JOIN CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID
        JOIN RegistrationCourseOfferingRating rcor ON rco.RegistrationCourseOfferingID = rcor.RegistrationCourseOfferingID
        JOIN Registration r ON rco.RegistrationID = r.RegistrationID
        WHERE r.StudentID = @StudentID
          AND rco.EnrollmentStatus = 'Completed'
          AND rcor.RatingValue >= @GoodRating
    ),
    OtherStudents AS (
        SELECT r.StudentID
        FROM RegistrationCourseOffering rco
        JOIN CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID
        JOIN RegistrationCourseOfferingRating rcor ON rco.RegistrationCourseOfferingID = rcor.RegistrationCourseOfferingID
        JOIN Registration r ON rco.RegistrationID = r.RegistrationID
        JOIN StudentCourses sc ON co.CourseID = sc.CourseID
        WHERE r.StudentID <> @StudentID
          AND rco.EnrollmentStatus = 'Completed'
          AND rcor.RatingValue >= @GoodRating
        GROUP BY r.StudentID
        HAVING COUNT(DISTINCT co.CourseID) >= 2
    ),
    RecommendedCourses AS (
        SELECT DISTINCT co.CourseID
        FROM RegistrationCourseOffering rco
        JOIN CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID
        JOIN RegistrationCourseOfferingRating rcor ON rco.RegistrationCourseOfferingID = rcor.RegistrationCourseOfferingID
        JOIN Registration r ON rco.RegistrationID = r.RegistrationID
        JOIN OtherStudents os ON r.StudentID = os.StudentID
        WHERE rcor.RatingValue >= @GoodRating
          AND co.CourseID NOT IN (SELECT CourseID FROM StudentCourses)
    )
    SELECT C.SubjectCode, C.CourseNumber, C.Title
    FROM RecommendedCourses rc
    JOIN Course C ON rc.CourseID = C.CourseID;
END;
GO

-- Example test: Course Recommendations
-- EXEC dbo.procRecommendCourses @StudentID = 6


/* =================================================================================
   6. As a student
   I should be able to enroll in a course offering so that I can determine my registered 
   courses for a semester.
   DONE (does not work)
================================================================================= */
CREATE OR ALTER PROCEDURE dbo.procEnrollInCourseOffering
(
    @StudentID INT,
    @CRN INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RegistrationID INT, @CourseOfferingID INT;

    -- Get CourseOfferingID
    SELECT @CourseOfferingID = CourseOfferingID
    FROM CourseOffering
    WHERE CRN = @CRN;

    IF @CourseOfferingID IS NULL
    BEGIN
        RAISERROR('Course offering with CRN %d does not exist.', 16, 1, @CRN);
        RETURN;
    END;

    -- Get or create Registration for this student
    SELECT @RegistrationID = RegistrationID
    FROM Registration
    WHERE StudentID = @StudentID;

    IF @RegistrationID IS NULL
    BEGIN
        INSERT INTO Registration (StudentID) VALUES (@StudentID);
        SET @RegistrationID = SCOPE_IDENTITY();
    END;

    -- Check if already enrolled
    IF EXISTS (SELECT 1 FROM RegistrationCourseOffering 
               WHERE RegistrationID = @RegistrationID 
                 AND CourseOfferingID = @CourseOfferingID)
    BEGIN
        RAISERROR('Student %d is already enrolled in course offering with CRN %d.', 16, 1, @StudentID, @CRN);
        RETURN;
    END;

    -- Enroll
    INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus)
    VALUES (@RegistrationID, @CourseOfferingID, 'Enrolled');
END;
GO

create or alter procedure procEnrollStudentInCourseOfferingCalled
(@studentID int, @courseOfferingID int)
as
begin
	set nocount on;
	declare @enrollmentSucceeded bit, @enrollmentResponse nvarchar(100);

	execute @enrollmentSucceeded = procEnrollStudentInCourseOffering
		@studentID = @studentID, @courseOfferingID = @courseOfferingID, 
		@enrollmentResponse = @enrollmentResponse output;

	declare @tempTable table(EnrollmentResponse nvarchar(100), EnrollmentSucceeded bit);

	insert into @temptable(EnrollmentResponse, EnrollmentSucceeded)
	values (@enrollmentResponse, @enrollmentSucceeded);

	select EnrollmentResponse,EnrollmentSucceeded
	from @tempTable;

end;
go

-- 6. Example test: Cureently only gives a msg of:
--    "Student x already enrolled inc course y"
-- EXEC dbo.procEnrollInCourseOffering @StudentID = 2, @CRN = 30003;

/* By Jaxon - 
7.As a student

I want to be able to withdraw from a course offering

So that I have an option to not continue taking that course offering.*/

create or alter procedure procDropStudentFromCourseOffering
(
	@registrationID int, @courseOfferingID int
)
as
begin

	set nocount on;

	update RegistrationCourseOffering
	set EnrollmentStatus = 'Dropped',
		LastUpdate = GETDATE()
	where RegistrationID = @registrationID
	     and CourseOfferingID  = @courseOfferingID;

end;

/*
execute procDropStudentFromCourseOffering
	@studentID = 1, @courseOfferingID = 15
*/

go

create or alter procedure procDropStudentFromCourseOfferingCalled
(
	@studentID int, @courseOfferingID int
)
as
begin
	set nocount on;

	declare @registrationID int;

	select @registrationID = RegistrationID
	from Registration
	where StudentID = @studentID;

	execute procDropStudentFromCourseOffering @registrationID = @registrationID, 
	@courseOfferingID = @courseOfferingID;

	select EnrollmentStatus, RegistrationID, CourseOfferingID, LastUpdate
	from RegistrationCourseOffering
	where RegistrationID = @registrationID and CourseOfferingID = @courseOfferingID;
end;
go
-- Section II: TRIGGERS - Business Rules HW4

/* DONE- NADA
1. When a student enrolls in a Course Offering, the number of seats available should be reduced.
(As a student, need to know if any seats are available in a course offering) */

create or alter trigger trgReduceAvailableSeats -- resulting actions we need
on registrationCourseOffering -- table where event is happening

-- trigger event/action (inserted table mimics registrationCourseOffering, 
-- delete ( removes table) 
-- updated (deleted, inserted)
after insert 
as
begin
	declare @courseOfferingID int;
	select @courseOfferingID = CourseOfferingID	
	from inserted;

	update CourseOffering
	set NumberSeatsRemaining = NumberSeatsRemaining - 1
	where CourseOfferingID = @courseOfferingID;
end;
GO
/*
TEST EXAMPLE: WORKS

select * from Registration; 
select * from registrationCourseOffering where RegistrationID =1; 
select * from CourseOffering where CourseOfferingID = 16; -- remaining seats = 3

insert into registrationCourseOffering 
(RegistrationID, CourseOfferingID, EnrollmentStatus, LastUpdate)
values (1, 16, 'Enrolled', getdate()) 
*/


/* DONE - NADA
2. When a student withdraws from a Course Offering, the number of seats available should be increased.
(Again, as a student, need to know if any seats are available in a course offering) */

create or alter trigger trgIncreaseAvailableSeats -- resulting action we need
on RegistrationCourseOffering -- table where the event is happening
after update -- fires after EnrollmentStatus is updated
as
begin
    set nocount on;

    declare @courseOfferingID int;

    -- get the CourseOfferingID only when EnrollmentStatus changes from Enrolled to Dropped
    select @courseOfferingID = CourseOfferingID
    from deleted

    -- increase available seats by 1 for that course offering
    update CourseOffering
    set NumberSeatsRemaining = NumberSeatsRemaining + 1
    where CourseOfferingID = @courseOfferingID;
    end;
    go

    /*
    TEST EXAMPLE: WORKSSSS

select * from Registration; 
select * from registrationCourseOffering where RegistrationID =1; 

1. excute this: 
select * from CourseOffering where CourseOfferingID = 16; --3

2. Excute:
update RegistrationCourseOffering
set EnrollmentStatus = 'Dropped',
    LastUpdate = getdate()
where RegistrationID = 1
  and CourseOfferingID = 16;

  3. Excute again: it sould increment the NumberSeatsRemaining 
  select * from CourseOffering where CourseOfferingID = 16; --3

    */

/* =================================================================================
    3. When a student is assigned a grade for a Course Offering, the student's GPA should include that grade.
    (As a student, need to know that their GPA is correctly calculated and current).
    DONE BY Jaxon
================================================================================= */

IF COL_LENGTH('dbo.Student','GPA') IS NULL
BEGIN
    ALTER TABLE dbo.Student ADD GPA DECIMAL(4,3) NULL; -- store current cumulative GPA
END;
GO

-- Convert a letter grade to grade points (4.000 scale)
CREATE OR ALTER FUNCTION ufnGetGradePoints(@Letter NCHAR(2))
RETURNS DECIMAL(4,3)
AS
BEGIN
    DECLARE @GPA DECIMAL(4,3);
    SET @Letter = UPPER(TRIM(@Letter));
    SET @GPA = CASE @Letter
                WHEN 'A'  THEN 4.000
                WHEN 'B'  THEN 3.000
                WHEN 'C'  THEN 2.000
                WHEN 'D'  THEN 1.000
                WHEN 'F'  THEN 0.000
                ELSE NULL
            END;
    RETURN @GPA;    
END;
GO

-- Trigger 
CREATE OR ALTER TRIGGER trgAfterInsertUpdateGrade
ON dbo.RegistrationCourseOffering
AFTER INSERT, UPDATE
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @StudentId INT, @NewGPA DECIMAL(4,3);

    IF EXISTS (SELECT 1 FROM inserted WHERE FinalGrade IS NOT NULL)
    BEGIN
        -- Get the StudentId from the inserted rows
        SELECT TOP 1 @StudentId = r.StudentId
        FROM inserted i
        JOIN dbo.Registration r ON i.RegistrationID = r.RegistrationID; 

        -- Calculate the new GPA
        SELECT @NewGPA = AVG(dbo.ufnGetGradePoints(i.FinalGrade))
        FROM dbo.RegistrationCourseOffering i
        JOIN dbo.Registration r ON i.RegistrationID = r.RegistrationID
        WHERE r.StudentId = @StudentId AND i.FinalGrade IS NOT NULL;
        
        -- Update the Student's GPA
        UPDATE dbo.Student
        SET GPA = @NewGPA
        WHERE StudentId = @StudentId;
    END
END;
GO

/* -- Test Example:
DECLARE @StudentID INT = 1; 
DECLARE @TargetRCOID INT;

-- See current GPA and that student's course offerings
SELECT StudentID, GPA AS CurrentGPA_Before
FROM Student
WHERE StudentID = @StudentID;

SELECT rco.RegistrationCourseOfferingID,
       rco.FinalGrade,
       rco.RegistrationID
FROM RegistrationCourseOffering rco
JOIN Registration r ON rco.RegistrationID = r.RegistrationID
WHERE r.StudentID = @StudentID
ORDER BY rco.RegistrationCourseOfferingID;

-- Choose a specific RegistrationCourseOffering row to grade and update
SELECT TOP (2) @TargetRCOID = rco.RegistrationCourseOfferingID
FROM RegistrationCourseOffering rco
JOIN Registration r ON rco.RegistrationID = r.RegistrationID
WHERE r.StudentID = @StudentID;

UPDATE rco
SET FinalGrade = 'A'
FROM RegistrationCourseOffering rco
WHERE rco.RegistrationCourseOfferingID = @TargetRCOID;

-- Show GPA after trigger fires.
SELECT StudentID, GPA AS CurrentGPA_After
FROM Student
WHERE StudentID = @StudentID;

SELECT rco.RegistrationCourseOfferingID,
       rco.FinalGrade,
       rco.RegistrationID
FROM RegistrationCourseOffering rco
JOIN Registration r ON rco.RegistrationID = r.RegistrationID
WHERE r.StudentID = @StudentID
ORDER BY rco.RegistrationCourseOfferingID;

GO 

-- End test */


/* =================================================================================
    4. When a student rates a course offering, the average course offering rating should include that rating.
    (As an instructor, need to know that the course rating is correct and current).
    DONE BY OLIVIA
================================================================================= */
create or alter trigger trgUpdateAverageCourseRating
on RegistrationCourseOfferingRating
after insert, update, delete
as
begin
    set nocount on;

    declare @courseOfferingID int;

    -- Determine the CourseOfferingID based on the operation (insert, update, delete)
    if EXISTS (SELECT 1 FROM inserted)
    begin
        select @courseOfferingID = co.CourseOfferingID
        from inserted i
        join RegistrationCourseOffering rco ON i.RegistrationCourseOfferingID = rco.RegistrationCourseOfferingID
        join CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID;
    end
    else if EXISTS (SELECT 1 FROM deleted)
    begin
        select @courseOfferingID = co.CourseOfferingID
        from deleted d
        join RegistrationCourseOffering rco ON d.RegistrationCourseOfferingID = rco.RegistrationCourseOfferingID
        join CourseOffering co ON rco.CourseOfferingID = co.CourseOfferingID;
    end

    -- Update the CourseOfferingAverageRating for the CourseOffering
    if @courseOfferingID is not null
    begin
        update CourseOffering
        set CourseOfferingAverageRating = (
            select AVG(CAST(RatingValue AS FLOAT))
            from RegistrationCourseOfferingRating rcor
            join RegistrationCourseOffering rco ON rcor.RegistrationCourseOfferingID = rco.RegistrationCourseOfferingID
            where rco.CourseOfferingID = @courseOfferingID
        )
        where CourseOfferingID = @courseOfferingID;
    end
end;
go
/*
TEST EXAMPLE: WORKS
select * from CourseOffering where CourseOfferingID = 16; -- CourseOfferingAverageRating is null
    insert into RegistrationCourseOfferingRating
        (RegistrationCourseOfferingID, RatingValue, Comments)
        values (16, 5, 'Great course!') -- assuming 16 is a valid RegistrationCourseOfferingID

select * from CourseOffering where CourseOfferingID = 16; -- CourseOfferingAverageRating is now 5
    insert into RegistrationCourseOfferingRating
        (RegistrationCourseOfferingID, RatingValue, Comments)
        values (16, 3, 'Good course!') -- assuming 16 is a valid RegistrationCourseOfferingID

select * from CourseOffering where CourseOfferingID = 16; -- CourseOfferingAverageRating is now 4
    update RegistrationCourseOfferingRating
    set RatingValue = 4
        where RegistrationCourseOfferingRatingID = 1; -- assuming 1 is a valid RegistrationCourseOfferingID

select * from CourseOffering where CourseOfferingID = 16; -- CourseOfferingAverageRating is now 3.5
    delete from RegistrationCourseOfferingRating
        where RegistrationCourseOfferingRatingID = 1; -- assuming 1 is a valid RegistrationCourseOfferingID

select * from CourseOffering where CourseOfferingID = 16; -- CourseOfferingAverageRating is now 4
*/