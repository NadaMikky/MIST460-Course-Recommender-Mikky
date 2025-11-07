-- USE Homework3Group1;
GO

-- Safety drops (order matters due to FKs)
IF OBJECT_ID('AlumJob')        IS NOT NULL DROP TABLE AlumJob;
IF OBJECT_ID('Job')            IS NOT NULL DROP TABLE Job;
IF OBJECT_ID('AlumOrganization')        IS NOT NULL DROP TABLE AlumOrganization;
IF OBJECT_ID('Organization')            IS NOT NULL DROP TABLE Organization;
IF OBJECT_ID('StudentInterest')IS NOT NULL DROP TABLE StudentInterest;
IF OBJECT_ID('Interest')       IS NOT NULL DROP TABLE Interest;
IF OBJECT_ID('RegistrationCourseOfferingRating') IS NOT NULL DROP TABLE RegistrationCourseOfferingRating;
if object_id('RegistrationCourseOffering') is not null drop table RegistrationCourseOffering;
IF OBJECT_ID('Registration')   IS NOT NULL DROP TABLE Registration;
IF OBJECT_ID('MajorCourse')    IS NOT NULL DROP TABLE MajorCourse;
IF OBJECT_ID('CoursePrerequisite') IS NOT NULL DROP TABLE CoursePrerequisite;
IF OBJECT_ID('StudentMajor')   IS NOT NULL DROP TABLE StudentMajor;
IF OBJECT_ID('AlumMajor')   IS NOT NULL DROP TABLE AlumMajor;
IF OBJECT_ID('StudentCourseRecommendation')   IS NOT NULL DROP TABLE StudentCourseRecommendation;
IF OBJECT_ID('CourseOffering') IS NOT NULL DROP TABLE CourseOffering;
IF OBJECT_ID('Major')          IS NOT NULL DROP TABLE Major;
IF OBJECT_ID('Course')         IS NOT NULL DROP TABLE Course;
IF OBJECT_ID('Alum')           IS NOT NULL DROP TABLE Alum;
IF OBJECT_ID('Instructor')     IS NOT NULL DROP TABLE Instructor;
IF OBJECT_ID('Student')        IS NOT NULL DROP TABLE Student;
IF OBJECT_ID('AppUser')        IS NOT NULL DROP TABLE AppUser;
GO

/* =========================
   Core users and subtypes
   ========================= */

CREATE TABLE AppUser (
    AppUserID       INT IDENTITY(1,1) CONSTRAINT PK_AppUser PRIMARY KEY,
    FullName        NVARCHAR(100)  NOT NULL,
    Email           NVARCHAR(320)  NOT NULL CONSTRAINT UQ_AppUser_Email UNIQUE,
    PasswordHash    VARBINARY(64)  NOT NULL,      -- store salted hash
    UserRole        NVARCHAR(20)   NOT NULL,      -- 'Student','Advisor','Instructor','Alum' (from diagram)
    CreatedAt    DATETIME2(3)   NOT NULL CONSTRAINT DF_AppUser_CreatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_AppUser_UserRole CHECK (UserRole IN (N'Student',N'Advisor',N'Instructor',N'Alum'))
);
GO

CREATE TABLE Student (
    StudentID               INT CONSTRAINT PK_Student PRIMARY KEY,
    TotalCreditsCompleted   INT NOT NULL CONSTRAINT DF_Student_TCC DEFAULT (0),
    CONSTRAINT FK_Student_AppUser FOREIGN KEY (StudentID)
        REFERENCES AppUser(AppUserID) ON DELETE CASCADE,
    CONSTRAINT CK_Student_TCC CHECK (TotalCreditsCompleted >= 0)
);
GO

CREATE TABLE Instructor (
    InstructorID    INT CONSTRAINT PK_Instructor PRIMARY KEY,
    CONSTRAINT FK_Instructor_AppUser FOREIGN KEY (InstructorID)
        REFERENCES AppUser(AppUserID) ON DELETE CASCADE
);
GO

CREATE TABLE Alum (
    AlumID              INT CONSTRAINT PK_Alum PRIMARY KEY,
    CurrentIndustry     NVARCHAR(100) NULL,
    CONSTRAINT FK_Alum_AppUser FOREIGN KEY (AlumID)
        REFERENCES AppUser(AppUserID) ON DELETE CASCADE
);
GO

/* =========================
   Academic structures
   ========================= */

CREATE TABLE Major (
    MajorID     INT IDENTITY(1,1) CONSTRAINT PK_Major PRIMARY KEY,
    MajorName   NVARCHAR(200) NOT NULL,
    Department  NVARCHAR(200) NULL
);
GO

CREATE TABLE Course (
    CourseID        INT IDENTITY(1,1) CONSTRAINT PK_Course PRIMARY KEY,
    SubjectCode     NVARCHAR(10)   NOT NULL,      -- e.g., 'MIST'
    CourseNumber    NVARCHAR(10)   NOT NULL,      -- e.g., '460'
    Title           NVARCHAR(200)  NOT NULL,
    CourseDescription     NVARCHAR(MAX)  NULL,
    Credits         DECIMAL(4,1)   NOT NULL CONSTRAINT DF_Course_Credits DEFAULT (3.0),
	MajorsOnlyRequirement bit not null,
	RecommendedCapacity int not null default(0),
    CONSTRAINT UQ_Course_SubjectNumber UNIQUE (SubjectCode, CourseNumber),
    CONSTRAINT CK_Course_Credits CHECK (Credits > 0 AND Credits <= 12.0)
);
GO

CREATE TABLE CoursePrerequisite (
	CoursePrequisiteID int identity(1,1) not null,
    CourseID            INT NOT NULL,
    PrereqCourseID      INT NOT NULL,
    MinGrade            NCHAR(2) NULL, -- e.g., 'C','B-'
    CONSTRAINT PK_CoursePrerequisite PRIMARY KEY (CoursePrequisiteID),
	constraint UK_CoursePrerequisite unique (CourseID, PrereqCourseID),
    CONSTRAINT FK_CoursePrereq_Course FOREIGN KEY (CourseID)
        REFERENCES Course(CourseID) ON DELETE CASCADE,
    CONSTRAINT FK_CoursePrereq_PrereqCourse FOREIGN KEY (PrereqCourseID)
        REFERENCES Course(CourseID) ON DELETE NO ACTION,
    CONSTRAINT CK_CoursePrereq_NoSelf CHECK (CourseID <> PrereqCourseID)
);
GO

CREATE TABLE MajorCourse (
    MajorCourseID int identity(1,1) not null,
    MajorID         INT NOT NULL,
    CourseID        INT NOT NULL,
    RequirementType NVARCHAR(20) NOT NULL, -- 'Required' or 'Elective'
    MinGrade        NCHAR(2) NULL,
    CONSTRAINT PK_MajorCourse PRIMARY KEY (MajorCourseID), 
	constraint UK_MajorCourse unique(MajorID, CourseID),
    CONSTRAINT FK_MajorCourse_Major FOREIGN KEY (MajorID)
        REFERENCES Major(MajorID) ON DELETE CASCADE,
    CONSTRAINT FK_MajorCourse_Course FOREIGN KEY (CourseID)
        REFERENCES Course(CourseID) ON DELETE CASCADE,
    CONSTRAINT CK_MajorCourse_ReqType CHECK (RequirementType IN (N'Required',N'Elective'))
);
GO

CREATE TABLE StudentMajor (
    StudentMajorID int identity(1,1) not null,
	StudentID   INT NOT NULL,
    MajorID     INT NOT NULL,
    CONSTRAINT PK_StudentMajor PRIMARY KEY (StudentMajorID),
	constraint UK_StudentMajor unique (StudentID, MajorID),
    CONSTRAINT FK_StudentMajor_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_StudentMajor_Major FOREIGN KEY (MajorID)
        REFERENCES Major(MajorID) ON DELETE CASCADE
);
GO

create table AlumMajor (

	AlumMajorID int identity(1,1) not null,
	AlumID int not null,
	MajorID int not null,
	GraduationYear int null,
	constraint pkAlumMajor primary key(AlumMajorID),
	constraint fkAlumMajor_Alum foreign key(AlumID)
		references Alum(AlumID),
	constraint fkAlumMajor_Major foreign key(MajorID)
		references Major(MajorID)
);

/* =========================
   Offerings, enrollment, ratings
   ========================= */

CREATE TABLE CourseOffering (
    CourseOfferingID            INT IDENTITY(1,1) CONSTRAINT PK_CourseOffering PRIMARY KEY,
    CourseID                    INT NOT NULL,
    InstructorID                INT NOT NULL,
    CRN                         INT NOT NULL,
    CourseOfferingSemester      NVARCHAR(12) NOT NULL, -- 'Spring','Summer','Fall','Winter'
    CourseOfferingYear          SMALLINT NOT NULL,
    Section                     NVARCHAR(10) NULL,
    NumberSeatsRemaining        INT NOT NULL CONSTRAINT DF_CourseOffering_Seats DEFAULT (0),
    Location                    NVARCHAR(20) NOT NULL, -- 'Downtown','HSC','Evansdale','Online'
    CourseOfferingAverageRating DECIMAL(4,2) NOT NULL CONSTRAINT DF_CourseOffering_Avg DEFAULT (0.0),
    CONSTRAINT FK_CourseOffering_Course FOREIGN KEY (CourseID)
        REFERENCES Course(CourseID) ON DELETE CASCADE,
    CONSTRAINT FK_CourseOffering_Instructor FOREIGN KEY (InstructorID)
        REFERENCES Instructor(InstructorID) ON DELETE NO ACTION,
    CONSTRAINT UQ_CourseOffering_CRN_Year UNIQUE (CRN, CourseOfferingYear),
    CONSTRAINT CK_CourseOffering_Sem CHECK (CourseOfferingSemester IN (N'Spring',N'Summer',N'Fall',N'Winter')),
    CONSTRAINT CK_CourseOffering_Year CHECK (CourseOfferingYear BETWEEN 2000 AND 2100),
    CONSTRAINT CK_CourseOffering_Location CHECK (Location IN (N'Downtown',N'HSC',N'Evansdale',N'Online')),
    CONSTRAINT CK_CourseOffering_Seats CHECK (NumberSeatsRemaining >= 0),
    CONSTRAINT CK_CourseOffering_Avg CHECK (CourseOfferingAverageRating >= 0 AND CourseOfferingAverageRating <= 5)
);
GO

CREATE TABLE Registration (
    RegistrationID      INT IDENTITY(1,1) CONSTRAINT PK_Registration PRIMARY KEY,
    StudentID           INT NOT NULL,
    RegisteredAt		DATETIME2(3) NOT NULL CONSTRAINT DF_Registration_At DEFAULT SYSUTCDATETIME()
    --FinalGrade          NCHAR(2) NULL,
    CONSTRAINT FK_Registration_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE
);
GO

CREATE TABLE RegistrationCourseOffering (
    RegistrationCourseOfferingID INT IDENTITY(1,1) CONSTRAINT PK_RegistrationCourseOffering PRIMARY KEY,
    RegistrationID int not null,
	CourseOfferingID    INT NOT NULL,
    EnrollmentStatus    NVARCHAR(12) NOT NULL, -- 'Enrolled','Waitlisted','Dropped','Completed'
    LastUpdate			DATETIME2(3) NOT NULL 
		CONSTRAINT DF_RegistrationCourseOffering DEFAULT SYSUTCDATETIME(),
    FinalGrade          NCHAR(2) NULL,
	CONSTRAINT UQ_RegistrationCourseOffering 
		UNIQUE (RegistrationID, CourseOfferingID, EnrollmentStatus),
    constraint FK_RegistrationCourseOffering_Registration foreign key (RegistrationID)
		references Registration(RegistrationID) on delete cascade,
	CONSTRAINT FK_RegistrationCourseOffering_CourseOffering FOREIGN KEY (CourseOfferingID)
        REFERENCES CourseOffering(CourseOfferingID) ON DELETE CASCADE,
    CONSTRAINT CK_Registration_Status CHECK (EnrollmentStatus IN (N'Enrolled',N'Waitlisted',N'Dropped',N'Completed'))
);

CREATE TABLE RegistrationCourseOfferingRating (
    RegistrationCourseOfferingRatingID	INT IDENTITY(1,1) 
		CONSTRAINT PK_RegistrationCourseOfferingRating PRIMARY KEY,
	RegistrationCourseOfferingID		int not null,
	RatingValue							int NOT NULL,     -- 1..5
    RatingComments							NVARCHAR(1000) NULL,
    RatedAt             DATETIME2 NOT NULL CONSTRAINT Default_RatedAt DEFAULT SYSDATETIME()
    CONSTRAINT FK_Rating_RegistrationCourseOffering FOREIGN KEY (RegistrationCourseOfferingID)
        REFERENCES RegistrationCourseOffering(RegistrationCourseOfferingID) ON DELETE CASCADE,
    CONSTRAINT CK_Rating_Value CHECK (RatingValue BETWEEN 1 AND 5)
);
GO

/* =========================
   Student Interests and Course Recommendations
   ========================= */

CREATE TABLE Interest (
    InterestID      INT IDENTITY(1,1) CONSTRAINT PK_Interest PRIMARY KEY,
    InterestTopic    NVARCHAR(100) NOT NULL CONSTRAINT UQ_Interest_Name UNIQUE,
);
GO

CREATE TABLE StudentInterest (
    StudentInterestID int identity(1,1) not null,
	StudentID       INT NOT NULL,
    InterestID      INT NOT NULL,
    InterestLevel   TINYINT NOT NULL, -- 1..5 (from diagram)
    UpdatedAt    DATETIME2(3) NOT NULL CONSTRAINT DF_StudentInterest_At DEFAULT SYSDATETIME(),
    CONSTRAINT PK_StudentInterest PRIMARY KEY (StudentInterestID),
	constraint UK_StudentInterest unique (StudentID, InterestID),
    CONSTRAINT FK_StudentInterest_Student FOREIGN KEY (StudentID)
        REFERENCES Student(StudentID) ON DELETE CASCADE,
    CONSTRAINT FK_StudentInterest_Interest FOREIGN KEY (InterestID)
        REFERENCES Interest(InterestID) ON DELETE CASCADE,
    CONSTRAINT CK_StudentInterest_Level CHECK (InterestLevel BETWEEN 1 AND 5)
);
GO

create table StudentCourseRecommendation(
	StudentCourseRecommendationID int identity(1,1) not null,
	StudentID int not null,
	CourseID int not null,
	RecommendationDate datetime2 not null constraint Default_RecommendationDate default SYSDATETIME(),
	StudentDecision nvarchar(20) null, -- 'Accepted', 'Rejected', or null
	ReasonForDecision nvarchar(max) null,
	constraint pkStudentCourseRecommendation primary key(StudentCourseRecommendationID),
	constraint fkStudentCourseRecommendation_Student foreign key(StudentID)
			references Student(StudentID),
	constraint fkStudentCourseRecommendation_Course foreign key(CourseID)
			references Course(CourseID)
);
go

/* =========================
   Alumni recommendations
   ========================= */

CREATE TABLE Job (
    JobID           INT IDENTITY(1,1) CONSTRAINT PK_Job PRIMARY KEY,
    JobDescription  NVARCHAR(MAX) NOT NULL,
    Industry        NVARCHAR(100) NULL,
);
GO

CREATE TABLE AlumJob (
    AlumJobID   INT IDENTITY(1,1) CONSTRAINT PK_AlumJob PRIMARY KEY,
    AlumID      INT NOT NULL,
    JobID       INT NOT NULL,
	RecommendationLevel int not null,
    CONSTRAINT UQ_AlumJob UNIQUE (AlumID, JobID),
    CONSTRAINT FK_AlumJob_Alum FOREIGN KEY (AlumID)
        REFERENCES Alum(AlumID) ON DELETE CASCADE,
    CONSTRAINT FK_AlumJob_Job FOREIGN KEY (JobID)
        REFERENCES Job(JobID) ON DELETE CASCADE
);
GO

CREATE TABLE Organization (
    OrganizationID      INT IDENTITY(1,1) CONSTRAINT PK_Organization PRIMARY KEY,
    OrganizationName	NVARCHAR(MAX) NOT NULL,
    Industry			NVARCHAR(100) NULL,
);
GO

CREATE TABLE AlumOrganization (
    AlumOrganizationID   INT IDENTITY(1,1) CONSTRAINT PK_AlumOrganization PRIMARY KEY,
    AlumID      INT NOT NULL,
    OrganizationID       INT NOT NULL,
	RecommendationLevel int not null,
    CONSTRAINT UQ_AlumOrganization UNIQUE (AlumID, OrganizationID),
    CONSTRAINT FK_AlumOrganization_Alum FOREIGN KEY (AlumID)
        REFERENCES Alum(AlumID) ON DELETE CASCADE,
    CONSTRAINT FK_AlumOrganization_Organization FOREIGN KEY (OrganizationID)
        REFERENCES Organization(OrganizationID) ON DELETE CASCADE
);
GO

