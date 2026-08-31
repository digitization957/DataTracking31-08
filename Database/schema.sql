/* ============================================================
   DataTracking - Database Schema (Azure Database for MySQL)
   Target: the "AppDb" database (separate from the org's LoginDb,
   which owns login_tokenpass and is not created here).
   Replaces the dummy App_Data/*.json files used in the demo.
   ============================================================ */

CREATE DATABASE IF NOT EXISTS datatracking CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE datatracking;

CREATE TABLE Categories (
    CategoryId      INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ParentId        INT UNSIGNED    NULL,
    Level           TINYINT UNSIGNED NOT NULL,
    Name            VARCHAR(200)    NOT NULL,
    IsActive        TINYINT(1)      NOT NULL DEFAULT 1,
    CONSTRAINT CHK_Categories_Level CHECK (Level BETWEEN 1 AND 4),
    CONSTRAINT FK_Categories_Parent FOREIGN KEY (ParentId) REFERENCES Categories(CategoryId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX IX_Categories_ParentId ON Categories(ParentId);

-- Admin-configurable display names for the 4 category levels (e.g. rename "Department" to
-- "Plant"). Seeded with defaults on first use if missing; see Helpers/AppDb.EnsureCategoryLevelsTable.
CREATE TABLE CategoryLevels (
    Level           TINYINT UNSIGNED NOT NULL PRIMARY KEY,
    LabelName       VARCHAR(50)     NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO CategoryLevels (Level, LabelName) VALUES
    (1, 'Department'), (2, 'Category'), (3, 'Sub-Category'), (4, 'Type');


CREATE TABLE Subjects (
    SubjectId       INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    SubjectText     VARCHAR(500)    NOT NULL,
    CreatedOn       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UQ_Subjects_SubjectText (SubjectText)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX IX_Subjects_SubjectText ON Subjects(SubjectText);

CREATE TABLE Tags (
    TagId           INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TagName         VARCHAR(100)    NOT NULL,
    UNIQUE KEY UQ_Tags_TagName (TagName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX IX_Tags_TagName ON Tags(TagName);

-- tags historically used with a subject -> powers "related tags" suggestions
CREATE TABLE SubjectTags (
    SubjectId       INT UNSIGNED    NOT NULL,
    TagId           INT UNSIGNED    NOT NULL,
    PRIMARY KEY (SubjectId, TagId),
    CONSTRAINT FK_SubjectTags_Subject FOREIGN KEY (SubjectId) REFERENCES Subjects(SubjectId),
    CONSTRAINT FK_SubjectTags_Tag FOREIGN KEY (TagId) REFERENCES Tags(TagId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE Records (
    RecordId              CHAR(32)      NOT NULL PRIMARY KEY,   -- GUID, hex-only (no dashes)
    Token                 VARCHAR(100)  NOT NULL,  -- uploader's token; Name/Role resolved externally (LoginDb / JWT)
    DepartmentCategoryId  INT UNSIGNED  NULL,  -- level 1
    CategoryId             INT UNSIGNED  NULL,  -- level 2
    SubCategoryId          INT UNSIGNED  NULL,  -- level 3
    TypeCategoryId          INT UNSIGNED NULL,  -- level 4
    SubjectId              INT UNSIGNED  NOT NULL,
    Remark                 TEXT          NULL,
    CreatedOn              DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_Records_Dept FOREIGN KEY (DepartmentCategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Records_Cat FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Records_SubCat FOREIGN KEY (SubCategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Records_Type FOREIGN KEY (TypeCategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Records_Subject FOREIGN KEY (SubjectId) REFERENCES Subjects(SubjectId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX IX_Records_SubjectId ON Records(SubjectId);
CREATE INDEX IX_Records_Token ON Records(Token);
CREATE INDEX IX_Records_CreatedOn ON Records(CreatedOn);

CREATE TABLE RecordFiles (
    FileId          INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    RecordId        CHAR(32)        NOT NULL,
    OriginalName    VARCHAR(300)    NOT NULL,
    StoredName      VARCHAR(300)    NOT NULL,   -- GUID-based name on disk, prevents path traversal
    FileExtension   VARCHAR(20)     NOT NULL,
    FileSizeBytes   BIGINT UNSIGNED NOT NULL,
    UploadedOn      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT FK_RecordFiles_Record FOREIGN KEY (RecordId) REFERENCES Records(RecordId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX IX_RecordFiles_RecordId ON RecordFiles(RecordId);

CREATE TABLE RecordTags (
    RecordId        CHAR(32)        NOT NULL,
    TagId           INT UNSIGNED    NOT NULL,
    PRIMARY KEY (RecordId, TagId),
    CONSTRAINT FK_RecordTags_Record FOREIGN KEY (RecordId) REFERENCES Records(RecordId),
    CONSTRAINT FK_RecordTags_Tag FOREIGN KEY (TagId) REFERENCES Tags(TagId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
