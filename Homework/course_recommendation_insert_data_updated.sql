-- USE Homework3Group1;

SET NOCOUNT ON;

--BEGIN TRAN;

------------------------------------------------------------
-- 1) Majors
------------------------------------------------------------
INSERT INTO Major (MajorName, Department) VALUES
 (N'MIS',               N'John Chambers College of Business and Economics'),
 (N'Computer Science',  N'Lane Department of Computer Science and Electrical Engineering'),
 (N'Data Analytics',    N'John Chambers College of Business and Economics'),
 (N'Cybersecurity',     N'Lane Department of Computer Science and Electrical Engineering'),
 (N'Finance',           N'John Chambers College of Business and Economics');

DECLARE @MajorMIS INT       = (SELECT MajorID FROM Major WHERE MajorName = N'MIS');
DECLARE @MajorCS  INT       = (SELECT MajorID FROM Major WHERE MajorName = N'Computer Science');

------------------------------------------------------------
-- 2) Courses (WVU MIS & CS examples)
--    Titles reflect WVU catalog vernacular
------------------------------------------------------------
INSERT INTO Course (SubjectCode, CourseNumber, Title, CourseDescription, Credits, MajorsOnlyRequirement, RecommendedCapacity) VALUES
 (N'MIST', N'320', N'Managing Information Technology', N'Overview of IT management in organizations.', 3.0, 0, 100),
 (N'MIST', N'351', N'Database Management Systems',     N'Intro to database theory, design, implementation.', 3.0, 0, 60),
 (N'MIST', N'352', N'Business Application Programming',N'Fundamentals of programming for business apps.', 3.0, 0, 60),
 (N'MIST', N'353', N'Advanced Information Technology', N'Advanced IT topics and tools.', 3.0, 0, 55),
 (N'MIST', N'355', N'Data Communications',             N'Networks and data communications concepts.', 3.0, 0, 50),
 (N'MIST', N'450', N'Systems Analysis',                N'Systems approach; early SDLC phases.', 3.0, 0, 35),
 (N'MIST', N'452', N'Systems Design/Development',      N'Later SDLC phases; UI, data & implementation.', 3.0, 0, 35),
 (N'MIST', N'455', N'Introduction to Machine Learning',N'Foundations of machine learning.', 3.0, 0, 35),
 (N'MIST', N'460', N'Analysis and Design of AI and ML Systems', N'Analyzing and Designing Systems integrating AI and ML.', 3.0, 1, 30),
 (N'CS',   N'110', N'Introduction to Computer Science',N'Foundations of programming and problem solving.', 3.0, 0, 80),
 (N'CS',   N'111', N'Introduction to Data Structures', N'Introductory data structures & algorithms.', 3.0, 0, 40),
 (N'CS',   N'210', N'Intermediate Programming',        N'Object-oriented programming patterns and data.', 3.0, 0, 30);

DECLARE @cMIST320 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='320');
DECLARE @cMIST351 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='351');
DECLARE @cMIST352 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='352');
DECLARE @cMIST353 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='353');
DECLARE @cMIST355 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='355');
DECLARE @cMIST450 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='450');
DECLARE @cMIST452 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='452');
DECLARE @cMIST455 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='455');
DECLARE @cMIST460 INT = (SELECT CourseID FROM Course WHERE SubjectCode='MIST' AND CourseNumber='460');
DECLARE @cCS110  INT = (SELECT CourseID FROM Course WHERE SubjectCode='CS'   AND CourseNumber='110');
DECLARE @cCS111  INT = (SELECT CourseID FROM Course WHERE SubjectCode='CS'   AND CourseNumber='111');
DECLARE @cCS210  INT = (SELECT CourseID FROM Course WHERE SubjectCode='CS'   AND CourseNumber='210');

------------------------------------------------------------
-- 3) Course prerequisites (as requested)
--    MIST 351 -> 352
--    MIST 352 -> 353, 450
--    MIST 353 & 450 -> 452
--    MIST 452 & 455 -> 460
------------------------------------------------------------
INSERT INTO CoursePrerequisite (CourseID, PrereqCourseID, MinGrade) VALUES
 (@cMIST352, @cMIST351, N'C-'),
 (@cMIST353, @cMIST352, N'C-'),
 (@cMIST450, @cMIST352, N'C-'),
 (@cMIST452, @cMIST353, N'C-'),
 (@cMIST452, @cMIST450, N'C-'),
 (@cMIST460, @cMIST452, N'B'),
 (@cMIST460, @cMIST455, N'C');

------------------------------------------------------------
-- 4) MajorCourse mappings
------------------------------------------------------------
-- MIS required sequence
INSERT INTO MajorCourse (MajorID, CourseID, RequirementType, MinGrade) VALUES
 (@MajorMIS, @cMIST320, N'Required', N'C-'),
 (@MajorMIS, @cMIST351, N'Required', N'C-'),
 (@MajorMIS, @cMIST352, N'Required', N'C-'),
 (@MajorMIS, @cMIST353, N'Required', N'C-'),
 (@MajorMIS, @cMIST450, N'Required', N'C-'),
 (@MajorMIS, @cMIST452, N'Required', N'C-'),
 (@MajorMIS, @cMIST355, N'Elective', N'C-'),
 (@MajorMIS, @cMIST455, N'Elective', N'C'),
 (@MajorMIS, @cMIST460, N'Elective', N'C');

-- CS required examples
INSERT INTO MajorCourse (MajorID, CourseID, RequirementType, MinGrade) VALUES
 (@MajorCS,  @cCS110,  N'Required', N'C-'),
 (@MajorCS,  @cCS111,  N'Required', N'C-'),
 (@MajorCS,  @cCS210,  N'Required', N'C-'),
 (@MajorCS,  @cMIST351,N'Elective', N'C-');  -- cross-listed elective idea

------------------------------------------------------------
-- 5) AppUsers (Students, Instructors, Alumni)
------------------------------------------------------------
-- Students (12)
INSERT INTO AppUser (FullName, Email, PasswordHash, UserRole)
VALUES
 (N'Michael Jordan', N'mjordan@wvu.edu', 0x01, N'Student'),
 (N'Sarah Lee',      N'slee@wvu.edu',    0x01, N'Student'),
 (N'Alex Kim',       N'akim@wvu.edu',    0x01, N'Student'),
 (N'Priya Patel',    N'ppatel@wvu.edu',  0x01, N'Student'),
 (N'Daniel Smith',   N'dsmith@wvu.edu',  0x01, N'Student'),
 (N'Emily Chen',     N'echen@wvu.edu',   0x01, N'Student'),
 (N'Juan Garcia',    N'jgarcia@wvu.edu', 0x01, N'Student'),
 (N'Hannah Nguyen',  N'hnguyen@wvu.edu', 0x01, N'Student'),
 (N'Robert Brown',   N'rbrown@wvu.edu',  0x01, N'Student'),
 (N'Olivia Davis',   N'odavis@wvu.edu',  0x01, N'Student'),
 (N'Liam Wilson',    N'lwilson@wvu.edu', 0x01, N'Student'),
 (N'Zoe Martinez',   N'zmartinez@wvu.edu',0x01,N'Student');

-- Instructors (5)
INSERT INTO AppUser (FullName, Email, PasswordHash, UserRole)
VALUES
 (N'Dr. Karen Evans',  N'kevans@wvu.edu',  0x02, N'Instructor'),
 (N'Prof. Thomas Reed',N'treed@wvu.edu',   0x02, N'Instructor'),
 (N'Dr. Linda Park',   N'lpark@wvu.edu',   0x02, N'Instructor'),
 (N'Prof. James Carter',N'jcarter@wvu.edu',0x02, N'Instructor'),
 (N'Dr. Sophia Turner',N'sturner@wvu.edu', 0x02, N'Instructor');

-- Alumni (10)
INSERT INTO AppUser (FullName, Email, PasswordHash, UserRole)
VALUES
 (N'Alice Warren',   N'awarren@alum.wvu.edu', 0x03, N'Alum'),
 (N'Brian Young',    N'byoung@alum.wvu.edu',  0x03, N'Alum'),
 (N'Carla Ruiz',     N'cruiz@alum.wvu.edu',   0x03, N'Alum'),
 (N'David O''Neil',  N'doneil@alum.wvu.edu',  0x03, N'Alum'),
 (N'Ethan Brooks',   N'ebrooks@alum.wvu.edu', 0x03, N'Alum'),
 (N'Fatima Ali',     N'fali@alum.wvu.edu',    0x03, N'Alum'),
 (N'George King',    N'gking@alum.wvu.edu',   0x03, N'Alum'),
 (N'Helen Zhao',     N'hzhao@alum.wvu.edu',   0x03, N'Alum'),
 (N'Ian Clark',      N'iclark@alum.wvu.edu',  0x03, N'Alum'),
 (N'Julia Rossi',    N'jrossi@alum.wvu.edu',  0x03, N'Alum');

------------------------------------------------------------
-- 6) Subtype rows
------------------------------------------------------------
-- Students: map all student AppUsers to Student
INSERT INTO Student (StudentID, TotalCreditsCompleted)
SELECT AppUserID, CASE WHEN Email IN (N'echen@wvu.edu',N'jgarcia@wvu.edu',N'rbrown@wvu.edu',N'lwilson@wvu.edu') THEN 45 ELSE 60 END
FROM AppUser WHERE UserRole = N'Student';

-- Instructors
INSERT INTO Instructor (InstructorID)
SELECT AppUserID FROM AppUser WHERE UserRole = N'Instructor';

-- Alumni (set industries)
INSERT INTO Alum (AlumID, CurrentIndustry)
SELECT AppUserID,
       CASE ROW_NUMBER() OVER (ORDER BY AppUserID)
            WHEN 1 THEN N'Technology'
            WHEN 2 THEN N'Financial Services'
            WHEN 3 THEN N'Healthcare IT'
            WHEN 4 THEN N'Retail Tech'
            WHEN 5 THEN N'Consulting'
            WHEN 6 THEN N'Cybersecurity'
            WHEN 7 THEN N'Cloud Computing'
            WHEN 8 THEN N'Data Analytics'
            WHEN 9 THEN N'Manufacturing'
            ELSE N'Education Technology' END
FROM AppUser WHERE UserRole = N'Alum';

------------------------------------------------------------
-- 7) Student majors (ensure MIS & CS)
------------------------------------------------------------
-- MIS majors (include Michael Jordan + many)
INSERT INTO StudentMajor (StudentID, MajorID)
SELECT AppUserID, @MajorMIS FROM AppUser
WHERE Email IN (N'mjordan@wvu.edu',N'slee@wvu.edu',N'akim@wvu.edu',N'ppatel@wvu.edu',
                N'dsmith@wvu.edu',N'hnguyen@wvu.edu',N'odavis@wvu.edu',N'zmartinez@wvu.edu');

-- CS majors
INSERT INTO StudentMajor (StudentID, MajorID)
SELECT AppUserID, @MajorCS FROM AppUser
WHERE Email IN (N'echen@wvu.edu',N'jgarcia@wvu.edu',N'rbrown@wvu.edu',N'lwilson@wvu.edu');

------------------------------------------------------------
-- 8) Alum majors (at least 5; here we set all 10)
------------------------------------------------------------
INSERT INTO AlumMajor (AlumID, MajorID, GraduationYear)
SELECT a.AlumID, CASE WHEN (a.AlumID % 2)=0 THEN @MajorMIS ELSE @MajorCS END, 2019 + (a.AlumID % 6)
FROM Alum a;

------------------------------------------------------------
-- 9) Course Offerings (past terms; unique CRN/year)
------------------------------------------------------------
DECLARE @iKevans  INT = (SELECT InstructorID FROM Instructor i JOIN AppUser u ON u.AppUserID=i.InstructorID WHERE u.Email=N'kevans@wvu.edu');
DECLARE @iReed    INT = (SELECT InstructorID FROM Instructor i JOIN AppUser u ON u.AppUserID=i.InstructorID WHERE u.Email=N'treed@wvu.edu');
DECLARE @iPark    INT = (SELECT InstructorID FROM Instructor i JOIN AppUser u ON u.AppUserID=i.InstructorID WHERE u.Email=N'lpark@wvu.edu');
DECLARE @iCarter  INT = (SELECT InstructorID FROM Instructor i JOIN AppUser u ON u.AppUserID=i.InstructorID WHERE u.Email=N'jcarter@wvu.edu');
DECLARE @iTurner  INT = (SELECT InstructorID FROM Instructor i JOIN AppUser u ON u.AppUserID=i.InstructorID WHERE u.Email=N'sturner@wvu.edu');

INSERT INTO CourseOffering (CourseID, InstructorID, CRN, 
CourseOfferingSemester, CourseOfferingYear, Section, NumberSeatsRemaining, 
Location, CourseOfferingAverageRating)
VALUES
 (@cMIST351, @iKevans, 10001, N'Fall',   2023, N'001', 10, N'Evansdale', 4.60),
 (@cMIST352, @iKevans, 10002, N'Spring', 2024, N'001', 12, N'Evansdale', 4.55),
 (@cMIST353, @iReed,   10003, N'Fall',   2024, N'001',  8, N'Online',    4.70),
 (@cMIST450, @iPark,   10004, N'Spring', 2024, N'001',  5, N'Downtown',  4.20),
 (@cMIST452, @iCarter, 10005, N'Fall',   2024, N'001',  6, N'Evansdale', 4.80),
 (@cMIST455, @iKevans, 10008, N'Fall', 2024, N'001',  7, N'Downtown',    4.15),
 (@cMIST355, @iPark,   10006, N'Spring', 2023, N'001',  9, N'Downtown',  4.30),
 (@cMIST355, @iPark,   10007, N'Fall', 2023, N'001',  9, N'Downtown',  4.30),
 (@cCS110,   @iTurner, 20001, N'Fall',   2023, N'001', 15, N'Evansdale', 4.10),
 (@cCS111,   @iTurner, 20002, N'Spring', 2024, N'001', 14, N'Evansdale', 4.15),
 (@cCS210,   @iTurner, 20003, N'Fall',   2024, N'001', 13, N'Evansdale', 4.05),
 (@cMIST320, @iKevans, 10009, N'Spring', 2023, N'001',  7, N'Online',    4.25),
 (@cMIST455, @iKevans, 30001, N'Fall', 2025, N'001',  10, N'Downtown',    0.00),
 (@cMIST460, @iKevans, 30002, N'Fall', 2025, N'001',  0, N'Online',    0.00),
 (@cMIST460, @iKevans, 30003, N'Fall', 2025, N'002',  6, N'Downtown',    0.00),
 (@cMIST460, @iPark, 30004, N'Fall', 2025, N'003',  3, N'Online',    0.00);

 /*
 select * from CourseOffering;
 */
-- Handy IDs for offerings
DECLARE @o351F23 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE 
CRN=10001 AND CourseOfferingYear=2023);
DECLARE @o352S24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10002 AND CourseOfferingYear=2024);
DECLARE @o353F24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10003 AND CourseOfferingYear=2024);
DECLARE @o450S24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10004 AND CourseOfferingYear=2024);
DECLARE @o452F24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10005 AND CourseOfferingYear=2024);
DECLARE @o355S23 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10006 AND CourseOfferingYear=2023);
DECLARE @oCS110F23 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=20001 AND CourseOfferingYear=2023);
DECLARE @oCS111S24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=20002 AND CourseOfferingYear=2024);
DECLARE @oCS210F24 INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=20003 AND CourseOfferingYear=2024);
DECLARE @o320S23  INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10007 AND CourseOfferingYear=2023);
DECLARE @o455F24  INT = (SELECT CourseOfferingID FROM CourseOffering WHERE CRN=10008 AND CourseOfferingYear=2024);


------------------------------------------------------------
-- 10) Registrations (one per student for simplicity)
------------------------------------------------------------
INSERT INTO Registration (StudentID)
SELECT s.StudentID
FROM Student s;

-- Resolve RegistrationIDs for each student by email
DECLARE @regMJ     INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'mjordan@wvu.edu');
DECLARE @regLee    INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'slee@wvu.edu');
DECLARE @regKim    INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'akim@wvu.edu');
DECLARE @regPatel  INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'ppatel@wvu.edu');
DECLARE @regSmith  INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'dsmith@wvu.edu');
DECLARE @regChen   INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'echen@wvu.edu');
DECLARE @regGarcia INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'jgarcia@wvu.edu');
DECLARE @regNguyen INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'hnguyen@wvu.edu');
DECLARE @regBrown  INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'rbrown@wvu.edu');
DECLARE @regDavis  INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'odavis@wvu.edu');
DECLARE @regWilson INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'lwilson@wvu.edu');
DECLARE @regMart   INT = (SELECT r.RegistrationID FROM Registration r JOIN Student s ON s.StudentID=r.StudentID JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'zmartinez@wvu.edu');

------------------------------------------------------------
-- 11) RegistrationCourseOffering: enrollments to satisfy scenarios
--     EnrollmentStatus = 'Completed' for all below
------------------------------------------------------------
-- (A) MJ & Sarah Lee together in one offering, both rate highly -> MIST 351 (Fall 2023)
INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus, FinalGrade)
VALUES
 (@regMJ,  @o351F23, N'Completed', N'A'),
 (@regLee, @o351F23, N'Completed', N'A');

-- (B) MJ & Alex Kim together in 2 offerings; MJ high, Alex poor -> MIST 352 & 450 (Spring 2024)
INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus, FinalGrade)
VALUES
 (@regMJ,  @o352S24, N'Completed', N'A'),
 (@regKim, @o352S24, N'Completed', N'C'),
 (@regMJ,  @o450S24, N'Completed', N'A'),
 (@regKim, @o450S24, N'Completed', N'D');

-- (C) MJ & Priya Patel in 2 offerings; both high -> MIST 353 (Fall 2024) & MIST 452 (Fall 2024)
INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus, FinalGrade)
VALUES
 (@regMJ,    @o353F24, N'Completed', N'A'),
 (@regPatel, @o353F24, N'Completed', N'A'),
 (@regMJ,    @o452F24, N'Completed', N'A'),
 (@regPatel, @o452F24, N'Completed', N'A');

-- (D) MJ & Daniel Smith in 2 offerings; both high -> MIST 320 (Spring 2023) & MIST 355 (Spring 2023)
INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus, FinalGrade)
VALUES
 (@regMJ,    @o320S23, N'Completed', N'A'),
 (@regSmith, @o320S23, N'Completed', N'A'),
 (@regSmith, @o355S23, N'Completed', N'A');

-- Additional enrollments so other students have history (and to exceed 5 rows)
INSERT INTO RegistrationCourseOffering (RegistrationID, CourseOfferingID, EnrollmentStatus, FinalGrade)
VALUES
 (@regChen,   @oCS110F23, N'Completed', N'B'),
 (@regGarcia, @oCS110F23, N'Completed', N'B'),
 (@regBrown,  @oCS111S24, N'Completed', N'B'),
 (@regWilson, @oCS111S24, N'Completed', N'B'),
 (@regNguyen, @o351F23,   N'Completed', N'A'),
 (@regDavis,  @o352S24,   N'Completed', N'B'),
 (@regMart,   @o353F24,   N'Completed', N'A'),
 (@regMJ, @o455F24, N'Completed', N'A');

------------------------------------------------------------
-- 12) Ratings for the above enrollments
--     Use UQ (RegistrationID, CourseOfferingID) to find the RCO row
------------------------------------------------------------
-- Helpers: inline function via subselect
-- HIGH = 5, POOR = 2
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Excellent content and delivery.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o351F23;

INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Great instructor.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regLee AND rco.CourseOfferingID=@o351F23;

-- MJ high, Alex poor on two courses
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Loved the projects.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o352S24;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 2, N'Not my style.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regKim AND rco.CourseOfferingID=@o352S24;

INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Challenging but rewarding.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o450S24;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 2, N'Too theoretical for me.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regKim AND rco.CourseOfferingID=@o450S24;

-- MJ & Priya both high on two courses
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Advanced topics useful.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o353F24;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Enjoyed collaboration.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regPatel AND rco.CourseOfferingID=@o353F24;

INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Excellent capstone design.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o452F24;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Capstone experience was great.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regPatel AND rco.CourseOfferingID=@o452F24;

-- MJ & Daniel both high on two courses
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Great intro to IT mgmt.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o320S23;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Clear real-world context.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regSmith AND rco.CourseOfferingID=@o320S23;

INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Networking knowledge very helpful.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regMJ AND rco.CourseOfferingID=@o355S23;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 5, N'Hands-on labs were excellent.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regSmith AND rco.CourseOfferingID=@o355S23;

-- A few more ratings to ensure table has many rows
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 4, N'Solid course.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regChen AND rco.CourseOfferingID=@oCS110F23;
INSERT INTO RegistrationCourseOfferingRating (RegistrationCourseOfferingID, RatingValue, RatingComments)
SELECT rco.RegistrationCourseOfferingID, 4, N'Useful intro.'
FROM RegistrationCourseOffering rco WHERE rco.RegistrationID=@regGarcia AND rco.CourseOfferingID=@oCS110F23;

------------------------------------------------------------
-- 13) Interests & StudentInterests (≥3 per student; ≥2 high-level)
------------------------------------------------------------
INSERT INTO Interest (InterestTopic) VALUES
 (N'Databases'),
 (N'Systems Analysis'),
 (N'Data Communications'),
 (N'Software Engineering'),
 (N'Data Analytics'),
 (N'Cybersecurity'),
 (N'Cloud Computing'),
 (N'UX/UI'),
 (N'Artificial Intelligence'),
 (N'Machine Learning');

-- Helper: function to grab IDs
DECLARE @iDatabases INT        = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Databases');
DECLARE @iSysAnalysis INT      = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Systems Analysis');
DECLARE @iDataComms INT        = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Data Communications');
DECLARE @iSWE INT              = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Software Engineering');
DECLARE @iAnalytics INT        = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Data Analytics');
DECLARE @iCyber INT            = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Cybersecurity');
DECLARE @iCloud INT            = (SELECT InterestID FROM Interest WHERE InterestTopic=N'Cloud Computing');
DECLARE @iUX INT               = (SELECT InterestID FROM Interest WHERE InterestTopic=N'UX/UI');

-- Student ID helper
DECLARE @sMJ     INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'mjordan@wvu.edu');
DECLARE @sLee    INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'slee@wvu.edu');
DECLARE @sKim    INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'akim@wvu.edu');
DECLARE @sPatel  INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'ppatel@wvu.edu');
DECLARE @sSmith  INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'dsmith@wvu.edu');
DECLARE @sChen   INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'echen@wvu.edu');
DECLARE @sGarcia INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'jgarcia@wvu.edu');
DECLARE @sNguyen INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'hnguyen@wvu.edu');
DECLARE @sBrown  INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'rbrown@wvu.edu');
DECLARE @sDavis  INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'odavis@wvu.edu');
DECLARE @sWilson INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'lwilson@wvu.edu');
DECLARE @sMart   INT = (SELECT StudentID FROM Student s JOIN AppUser u ON u.AppUserID=s.StudentID WHERE u.Email=N'zmartinez@wvu.edu');

-- Michael Jordan (MIS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sMJ, @iDatabases, 5),
 (@sMJ, @iSysAnalysis, 5),
 (@sMJ, @iDataComms, 4);

-- Sarah Lee
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sLee, @iDatabases, 5),
 (@sLee, @iAnalytics, 4),
 (@sLee, @iUX, 3);

-- Alex Kim
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sKim, @iSWE, 5),
 (@sKim, @iCloud, 4),
 (@sKim, @iDatabases, 3);

-- Priya Patel
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sPatel, @iSysAnalysis, 5),
 (@sPatel, @iSWE, 5),
 (@sPatel, @iAnalytics, 4);

-- Daniel Smith
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sSmith, @iDataComms, 5),
 (@sSmith, @iCloud, 5),
 (@sSmith, @iDatabases, 3);

-- Emily Chen (CS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sChen, @iSWE, 5),
 (@sChen, @iCyber, 4),
 (@sChen, @iAnalytics, 3);

-- Juan Garcia (CS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sGarcia, @iCloud, 5),
 (@sGarcia, @iSWE, 4),
 (@sGarcia, @iUX, 3);

-- Hannah Nguyen (MIS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sNguyen, @iAnalytics, 5),
 (@sNguyen, @iDatabases, 4),
 (@sNguyen, @iUX, 3);

-- Robert Brown (CS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sBrown, @iCyber, 5),
 (@sBrown, @iSWE, 4),
 (@sBrown, @iDatabases, 3);

-- Olivia Davis (MIS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sDavis, @iSysAnalysis, 5),
 (@sDavis, @iAnalytics, 4),
 (@sDavis, @iCloud, 3);

-- Liam Wilson (CS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sWilson, @iSWE, 5),
 (@sWilson, @iCloud, 4),
 (@sWilson, @iDataComms, 3);

-- Zoe Martinez (MIS)
INSERT INTO StudentInterest (StudentID, InterestID, InterestLevel) VALUES
 (@sMart, @iDatabases, 5),
 (@sMart, @iAnalytics, 4),
 (@sMart, @iSysAnalysis, 4);

------------------------------------------------------------
-- 14) Jobs & Organizations
------------------------------------------------------------
INSERT INTO Job (JobDescription, Industry) VALUES
 (N'Data Analyst',             N'Technology'),
 (N'Software Engineer',        N'Technology'),
 (N'Business Systems Analyst', N'Consulting'),
 (N'Cybersecurity Analyst',    N'Cybersecurity'),
 (N'Product Manager',          N'Technology'),
 (N'Database Administrator',   N'Technology');

INSERT INTO Organization (OrganizationName, Industry) VALUES
 (N'TechCorp',        N'Technology'),
 (N'DataWorks',       N'Data Analytics'),
 (N'CyberSecure LLC', N'Cybersecurity'),
 (N'CloudNine',       N'Cloud Computing'),
 (N'FinServ Inc.',    N'Financial Services'),
 (N'HealthIT Systems',N'Healthcare IT');

-- Map alumni to at least 3 jobs + 3 orgs each, high recommendation (5)
-- First five alumni -> first three jobs/orgs
INSERT INTO AlumJob (AlumID, JobID, RecommendationLevel)
SELECT a.AlumID, j.JobID, 5
FROM Alum a
JOIN AppUser u ON u.AppUserID=a.AlumID
JOIN Job j ON j.JobDescription IN (N'Data Analyst',N'Software Engineer',N'Business Systems Analyst')
WHERE u.Email IN (N'awarren@alum.wvu.edu',N'byoung@alum.wvu.edu',N'cruiz@alum.wvu.edu',N'doneil@alum.wvu.edu',N'ebrooks@alum.wvu.edu');

INSERT INTO AlumOrganization (AlumID, OrganizationID, RecommendationLevel)
SELECT a.AlumID, o.OrganizationID, 5
FROM Alum a
JOIN AppUser u ON u.AppUserID=a.AlumID
JOIN Organization o ON o.OrganizationName IN (N'TechCorp',N'DataWorks',N'CyberSecure LLC')
WHERE u.Email IN (N'awarren@alum.wvu.edu',N'byoung@alum.wvu.edu',N'cruiz@alum.wvu.edu',N'doneil@alum.wvu.edu',N'ebrooks@alum.wvu.edu');

-- Next five alumni -> last three jobs/orgs
INSERT INTO AlumJob (AlumID, JobID, RecommendationLevel)
SELECT a.AlumID, j.JobID, 5
FROM Alum a
JOIN AppUser u ON u.AppUserID=a.AlumID
JOIN Job j ON j.JobDescription IN (N'Cybersecurity Analyst',N'Product Manager',N'Database Administrator')
WHERE u.Email IN (N'fali@alum.wvu.edu',N'gking@alum.wvu.edu',N'hzhao@alum.wvu.edu',N'iclark@alum.wvu.edu',N'jrossi@alum.wvu.edu');

INSERT INTO AlumOrganization (AlumID, OrganizationID, RecommendationLevel)
SELECT a.AlumID, o.OrganizationID, 5
FROM Alum a
JOIN AppUser u ON u.AppUserID=a.AlumID
JOIN Organization o ON o.OrganizationName IN (N'CloudNine',N'FinServ Inc.',N'HealthIT Systems')
WHERE u.Email IN (N'fali@alum.wvu.edu',N'gking@alum.wvu.edu',N'hzhao@alum.wvu.edu',N'iclark@alum.wvu.edu',N'jrossi@alum.wvu.edu');

------------------------------------------------------------
-- 15) Student Course Recommendations (≥5 rows; include 1 for MJ)
------------------------------------------------------------
INSERT INTO StudentCourseRecommendation (StudentID, CourseID, StudentDecision, ReasonForDecision)
VALUES
 (@sMJ,    @cMIST355, NULL, N'Recommended based on high interest in Data Communications and Systems Analysis.'),
 (@sLee,   @cMIST452, NULL, N'Capstone design aligns with databases and analytics interests.'),
 (@sPatel, @cMIST450, NULL, N'Strong systems analysis/SE interests match course outcomes.'),
 (@sChen,  @cCS210,   NULL, N'Next step after CS 110/111 and strong SWE interest.'),
 (@sNguyen,@cMIST351, NULL, N'High interest in databases and analytics.');

--COMMIT TRAN;
