CREATE database msds;

CREATE TABLE msds.Courses (
	Mnemonic varchar(255) NOT NULL,
    NAME varchar(255) NOT NULL,
    Status boolean default TRUE,
    description varchar(255) NOT NULL
);


CREATE TABLE msds.Instructor (
	Name varchar(255) NOT NULL,
    computingID varchar(255) NOT NULL,
    Status boolean default TRUE,
    PRIMARY KEY (computingID)
);

CREATE TABLE msds.LO (
	Mnemonic varchar(255) NOT NULL,
	LearningOutcome varchar(255) NOT NULL,
    Status boolean,
    ID int NOT NULL auto_increment,
    PRIMARY KEY(ID)
);

CREATE TABLE msds.SemesterSchedule (
	Mnemonic varchar(255) NOT NULL,
    InstructorComCoursesputingID varchar(255) NOT NULL,
    Semester DATE,
    PRIMARY KEY (Semester, Mnemonic)
);
