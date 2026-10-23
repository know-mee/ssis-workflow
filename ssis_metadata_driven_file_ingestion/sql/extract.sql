use demo
go
CREATE TABLE test.ExtractConfig (
    ExtractId             INT IDENTITY PRIMARY KEY,
    ExtractName           VARCHAR(100)  NOT NULL UNIQUE,   -- name passed to the package
    SourceSchema          SYSNAME       NULL,              -- L3 schema
    SourceObject          SYSNAME       NULL,              -- table or view
    ColumnList            VARCHAR(MAX)  NULL,              -- blank = all; else 'CustId,Name,City'
    DateColumn            SYSNAME       NULL,              -- filter: this day's rows only
    WhereClause           VARCHAR(MAX)  NULL,              -- extra static filter, e.g. Status = 'A'
    CustomQuery           VARCHAR(MAX)  NULL,              -- overrides the four above; may use @ExtractDate
    Delimiter             VARCHAR(10)   NOT NULL DEFAULT ',',   -- ',' '|' 'TAB'
    TextQualifier         CHAR(1)       NULL DEFAULT '"',
    IncludeHeader         BIT           NOT NULL DEFAULT 1,
    FileEncoding          VARCHAR(20)   NOT NULL DEFAULT 'UTF8',  -- UTF8, UTF8BOM, ASCII, UTF16
    OutputPath            VARCHAR(500)  NOT NULL,
    OutputFileNamePattern VARCHAR(200)  NOT NULL,          -- CUSTOMER_EXT_{yyyyMMdd}.csv
    CreateDoneFile        BIT           NOT NULL DEFAULT 0,
    IsActive              BIT           NOT NULL DEFAULT 1
);

CREATE TABLE test.ExtractAudit (
    AuditId       BIGINT IDENTITY(1,1) PRIMARY KEY,
    ExtractName   VARCHAR(100)  NOT NULL,
    ExtractDate   DATE          NULL,
    OutputFile    NVARCHAR(500) NULL,
    RowsExtracted BIGINT        NULL,
    Status        VARCHAR(20)   NOT NULL,        -- SUCCESS / FAILED
    ErrorMessage  NVARCHAR(MAX) NULL,
    ExecutionId   VARCHAR(50)   NULL,
    ExtractedOn   DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);

CREATE UNIQUE INDEX UX_ExtractAudit_Success
    ON test.ExtractAudit (ExtractName, ExtractDate) WHERE Status = 'SUCCESS';

ALTER TABLE test.ExtractConfig ADD
    ParallelStreams INT NOT NULL DEFAULT 1,
    PartitionColumn SYSNAME NULL;      -- used to split rows across streams

SELECT        _RowId, CustomerID, FirstName, LastName, City, Country, _LoadDate
FROM            stg.Customer

INSERT INTO test.ExtractConfig
    (ExtractName, SourceSchema, SourceObject, ColumnList, DateColumn, WhereClause, CustomQuery,
     Delimiter, TextQualifier, IncludeHeader, FileEncoding, OutputPath, OutputFileNamePattern,
     CreateDoneFile, IsActive)
VALUES
    ('CUSTOMER_EXT1',
     'stg',
     'Customer',
     'CustomerID,FirstName,LastName,City,Country',   -- only the non-underscore columns
     '_LoadDate',                                    -- filtered by the ExtractDate parameter
     NULL,
     NULL,
     ',', '"', 1, 'UTF8',
     'E:\Work\ssis-workflow\ssis_metadata_driven_file_ingestion\Notes\sales_sample_csv\outbound',
     'CUSTOMER_EXT_{yyyyMMdd}.csv',
     0, 1);


UPDATE test.ExtractConfig
SET ParallelStreams = 4, PartitionColumn = '_RowId'
WHERE ExtractName = 'CUSTOMER_EXT1';

