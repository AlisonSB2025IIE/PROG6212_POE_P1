CREATE DATABASE RaceDayDb;
GO

USE RaceDayDb;
GO


-- Creating a table for Users
CREATE TABLE dbo.Users
(
userID INT IDENTITY(1,1) PRIMARY KEY,
userName NVARCHAR(50) NOT NULL,
email NVARCHAR(255) NOT NULL,
passwordHash NVARCHAR(255) NOT NULL,
role NVARCHAR(20) NOT NULL
        -- If someone registers and no role is supplied, they get a participant role by default
CONSTRAINT DF_Users_Role DEFAULT ('Participant'),

CONSTRAINT UQ_Users_UserName UNIQUE (UserName),
CONSTRAINT CK_Users_Role CHECK (Role IN ('Participant', 'Organiser'))
);
GO

-- Creating a table for Organiser
CREATE TABLE dbo.Organiser
(
organiserID INT IDENTITY(1,1) PRIMARY KEY,
firstName NVARCHAR(50) NOT NULL,
lastName NVARCHAR(50) NOT NULL,
contactNumber NVARCHAR(20) NOT NULL,
userID INT NOT NULL,

CONSTRAINT UQ_Organiser_UserID UNIQUE (UserID),
CONSTRAINT FK_Organiser_user FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID)
);
GO

-- Creating a table for Participant
CREATE TABLE dbo.Participant
(
participantID INT IDENTITY(1,1) PRIMARY KEY,
raceDayNumber NVARCHAR(20) NOT NULL,
firstName NVARCHAR(50) NOT NULL,
lastName NVARCHAR(50) NOT NULL,
dob DATE NOT NULL, 
contactNumber NVARCHAR(20) NOT NULL,
emergencyContactName NVARCHAR(100) NOT NULL,
emergencyContactNumber NVARCHAR(20) NOT NULL,
userID INT NOT NULL,

CONSTRAINT UQ_Participant_raceDayNumber UNIQUE (raceDayNumber),
CONSTRAINT UQ_Participant_userID UNIQUE (userID),
CONSTRAINT FK_Participant_user FOREIGN KEY (userID) REFERENCES dbo.Users(userID)
);
GO

-- Creating a table for Event
CREATE TABLE dbo.Event
(
eventID INT IDENTITY(1,1) PRIMARY KEY,
raceName NVARCHAR(50) NOT NULL,
raceDescription NVARCHAR(1000) NOT NULL,
raceDate DATE NOT NULL,
raceLocation NVARCHAR(1000) NOT NULL,
raceDistance NVARCHAR(20)NOT NULL,
raceEventType NVARCHAR(20) NOT NULL,
registrationOpenDate DATE NOT NULL,
registrationCloseDate DATE NOT NULL,
organiserID INT NOT NULL,

CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID) REFERENCES dbo.Organiser(OrganiserID),
CONSTRAINT CK_Event_Type CHECK (RaceEventType IN ('Run', 'Walk', 'Cycle')),
CONSTRAINT CK_Event_RegistrationDates CHECK (RegistrationCloseDate >= RegistrationOpenDate)
);
GO

-- Creating a table for Category
CREATE TABLE dbo.Category
(
categoryID INT IDENTITY(1,1) PRIMARY KEY,
categoryName NVARCHAR(20)NOT NULL,
minAge INT NOT NULL,
maxAge INT NOT NULL,
distance NVARCHAR(20)NOT NULL,
eventID INT NOT NULL,

CONSTRAINT FK_Category_Event FOREIGN KEY (eventID) REFERENCES dbo.Event(eventID),
CONSTRAINT CK_Category_AgeRange CHECK (minAge <= maxAge),
CONSTRAINT UQ_Category_Event_Name UNIQUE (EventID, CategoryName)
);
GO

-- Creating a table for Registration
CREATE TABLE dbo.Registration
(
registrationID INT IDENTITY(1,1) PRIMARY KEY,
       -- If a participant enters and the system does not send a date, by default, today's date is saved
registrationDate DATE NOT NULL CONSTRAINT DF_Registration_Date default (CONVERT(DATE, GETDATE())),
eventID INT NOT NULL,
categoryID INT NOT NULL,
participantID INT NOT NULL,

CONSTRAINT FK_Registration_Event FOREIGN KEY (eventID) REFERENCES dbo.Event(eventID),
CONSTRAINT FK_Registration_Category FOREIGN KEY (categoryID) REFERENCES dbo.Category(categoryID),
CONSTRAINT FK_Registration_Participant FOREIGN KEY (participantID) REFERENCES dbo.Participant(participantID),
CONSTRAINT UQ_Registration_Participant_Event UNIQUE (participantID,EventID)
);
GO

-- Creating a table for Result
CREATE TABLE dbo.Result
(
resultID INT IDENTITY(1,1) PRIMARY KEY,
finishTime TIME(0) NOT NULL,
positioning INT NOT NULL,
registrationID INT NOT NULL,

CONSTRAINT UQ_Result_RegistrationID UNIQUE (RegistrationID),
CONSTRAINT FK_Result_Registration FOREIGN KEY (RegistrationID) REFERENCES dbo.Registration(RegistrationID),
CONSTRAINT CK_Result_Positioning CHECK (Positioning >= 1)
);
GO
-- The following seed data has kindly been supplied by ChatGPT(OpenAI)
-- Seed data: Users
INSERT INTO dbo.Users (UserName, Email, PasswordHash, Role)
VALUES
    ('organiser_ali', 'ali@gmail.co.za',
     '$2a$12$SeededHashForAliOrganiserOnly000000000000000000000000',
     'Organiser'),

    ('organiser_paul', 'paul@gmail.co.za',
     '$2a$12$SeededHashForPaulOrganiserOnly000000000000000000000000',
     'Organiser'),

    ('participant_lerato', 'lerato@gmail.com',
     '$2a$12$SeededHashForLeratoParticipantOnly00000000000000000',
     'Participant'),

    ('participant_james', 'james@gmail.com',
     '$2a$12$SeededHashForJamesParticipantOnly000000000000000000',
     'Participant');
GO

-- Seed data: Organisers
INSERT INTO dbo.Organiser (FirstName, LastName, ContactNumber, UserID)
VALUES
(
    'Ali',
    'Naidoo',
    '+27 82 555 0101',
    (SELECT UserID FROM dbo.Users WHERE UserName = 'organiser_ali')
),
(
    'Paul',
    'Dlamini',
    '+27 82 555 0102',
    (SELECT UserID FROM dbo.Users WHERE UserName = 'organiser_paul')
);
GO

-- Seed data: Participants
INSERT INTO dbo.Participant
(
    RaceDayNumber,
    FirstName,
    LastName,
    DOB,
    ContactNumber,
    EmergencyContactName,
    EmergencyContactNumber,
    UserID
)
VALUES
(
    'RD1001',
    'Lerato',
    'Mokoena',
    '2003-05-16',
    '+27 82 555 0201',
    'Thandi Mokoena',
    '+27 82 555 0301',
    (SELECT UserID FROM dbo.Users WHERE UserName = 'participant_lerato')
),
(
    'RD1002',
    'James',
    'Pillay',
    '2008-07-14',
    '+27 82 555 0202',
    'Priya Pillay',
    '+27 82 555 0302',
    (SELECT UserID FROM dbo.Users WHERE UserName = 'participant_james')
);
GO

-- Seed data: Events
INSERT INTO dbo.Event
(
    RaceName,
    RaceDescription,
    RaceDate,
    RaceLocation,
    RaceDistance,
    RaceEventType,
    RegistrationOpenDate,
    RegistrationCloseDate,
    OrganiserID
)
VALUES
(
    'Durban Sunrise Run',
    'A scenic road-running event along the Durban beachfront.',
    '2027-03-21',
    'Durban Beachfront',
    '10 km',
    'Run',
    '2026-11-01',
    '2027-03-01',
    (SELECT OrganiserID FROM dbo.Organiser
     WHERE UserID = (SELECT UserID FROM dbo.Users WHERE UserName = 'organiser_ali'))
),
(
    'Umhlanga Coastal Walk',
    'A relaxed coastal walking event for all eligible entrants.',
    '2027-04-18',
    'Umhlanga Promenade',
    '5 km',
    'Walk',
    '2027-01-01',
    '2027-04-01',
    (SELECT OrganiserID FROM dbo.Organiser
     WHERE UserID = (SELECT UserID FROM dbo.Users WHERE UserName = 'organiser_paul'))
),
(
    'Midlands Cycle Challenge',
    'A road cycling challenge through the KwaZulu-Natal Midlands.',
    '2027-05-23',
    'Howick',
    '40 km',
    'Cycle',
    '2027-02-01',
    '2027-05-01',
    (SELECT OrganiserID FROM dbo.Organiser
     WHERE UserID = (SELECT UserID FROM dbo.Users WHERE UserName = 'organiser_ali'))
);
GO

-- Seed data: Categories for each event
INSERT INTO dbo.Category (CategoryName, MinAge, MaxAge, Distance, EventID)
VALUES
('Under 20', 0, 19, '10 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run')),

('Senior', 20, 39, '10 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run')),

('Under 20', 0, 19, '5 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Umhlanga Coastal Walk')),

('Senior', 20, 39, '5 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Umhlanga Coastal Walk')),

('Under 20', 0, 19, '40 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Midlands Cycle Challenge')),

('Senior', 20, 39, '40 km',
 (SELECT EventID FROM dbo.Event WHERE RaceName = 'Midlands Cycle Challenge'));
GO

-- Seed data: Sample registrations
-- RegistrationDate is omitted deliberately: its DEFAULT inserts today's date.
INSERT INTO dbo.Registration (EventID, CategoryID, ParticipantID)
VALUES
(
    (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run'),
    (SELECT CategoryID FROM dbo.Category
     WHERE CategoryName = 'Under 20'
       AND EventID = (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run')),
    (SELECT ParticipantID FROM dbo.Participant WHERE RaceDayNumber = 'RD1002')
),
(
    (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run'),
    (SELECT CategoryID FROM dbo.Category
     WHERE CategoryName = 'Senior'
       AND EventID = (SELECT EventID FROM dbo.Event WHERE RaceName = 'Durban Sunrise Run')),
    (SELECT ParticipantID FROM dbo.Participant WHERE RaceDayNumber = 'RD1001')
),
(
    (SELECT EventID FROM dbo.Event WHERE RaceName = 'Umhlanga Coastal Walk'),
    (SELECT CategoryID FROM dbo.Category
     WHERE CategoryName = 'Senior'
       AND EventID = (SELECT EventID FROM dbo.Event WHERE RaceName = 'Umhlanga Coastal Walk')),
    (SELECT ParticipantID FROM dbo.Participant WHERE RaceDayNumber = 'RD1001')
);
GO

-- To View all tables
SELECT * FROM dbo.Users;
SELECT * FROM dbo.Organiser;
SELECT * FROM dbo.Participant;
SELECT * FROM dbo.Event;
SELECT * FROM dbo.Category;
SELECT * FROM dbo.Registration;

-- To see joined result for participants and the races they entered
SELECT
    p.RaceDayNumber,
    p.FirstName,
    p.LastName,
    e.RaceName,
    c.CategoryName,
    r.RegistrationDate
FROM dbo.Registration AS r
JOIN dbo.Participant AS p ON r.ParticipantID = p.ParticipantID
JOIN dbo.Event AS e ON r.EventID = e.EventID
JOIN dbo.Category AS c ON r.CategoryID = c.CategoryID;