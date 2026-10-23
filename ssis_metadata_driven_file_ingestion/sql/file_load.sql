USE demo
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg') EXEC('CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'test') EXEC('CREATE SCHEMA test');
GO
CREATE TABLE test.FileConfig (
    ConfigId        INT IDENTITY PRIMARY KEY,
    FeedName        VARCHAR(100)  NOT NULL UNIQUE,   -- logical name passed to the package
    FilePath        VARCHAR(500)  NOT NULL,          -- \\server\landing\customer
    FileNamePattern VARCHAR(200)  NOT NULL,          -- CUSTOMER_{yyyyMMdd}.csv
    Delimiter       VARCHAR(10)   NOT NULL,          -- ',' or '|' or 'TAB'
    HasHeader       BIT           NOT NULL,
    FieldCount      INT           NOT NULL,
    FieldNames      VARCHAR(MAX)  NULL,              -- 'CustId,Name,City' (needed when HasHeader = 0)
    StagingSchema   SYSNAME       NOT NULL DEFAULT 'stg',
    StagingTable    SYSNAME       NOT NULL,
    ArchivePath     VARCHAR(500)  NULL,
    IsActive        BIT           NOT NULL DEFAULT 1
);

INSERT INTO test.FileConfig
    (FeedName, FilePath, FileNamePattern, Delimiter, HasHeader, FieldCount,
     FieldNames, StagingSchema, StagingTable, ArchivePath, IsActive)
VALUES
    (N'CustomerFeed',
     N'E:\Work\ssis-workflow\ssis_metadata_driven_file_ingestion\Notes\sales_sample_csv\csv',
     N'CUSTOMER_{yyyyMMdd}.csv',
     N',',
     1,
     5,
     N'CustomerID,FirstName,LastName,City,Country',
     N'stg',
     N'Customer',
     N'\\fileserver\archive\customer',
     1);

select * from [stg].[Customer]

CREATE TABLE test.FileLoadAudit (
    AuditId        BIGINT IDENTITY(1,1) PRIMARY KEY,
    FeedName       VARCHAR(100)   NOT NULL,
    FileDate       DATE           NULL,
    FullFilePath   NVARCHAR(500)  NULL,
    StagingTable   NVARCHAR(256)  NULL,
    RowsLoaded     BIGINT         NULL,
    Status         VARCHAR(20)    NOT NULL,      -- 'SUCCESS' or 'FAILED'
    ErrorMessage   NVARCHAR(MAX)  NULL,
    ExecutionId    VARCHAR(50)    NULL,          -- System::ServerExecutionID
    LoadedOn       DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    LoadedBy       SYSNAME        NOT NULL DEFAULT SUSER_SNAME()
);

CREATE INDEX IX_FileLoadAudit_Feed_Date
    ON test.FileLoadAudit (FeedName, FileDate);

