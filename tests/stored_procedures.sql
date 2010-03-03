/*
 * pymssql stored procedure test suite script
 *
 * These procedures are used to test that the data type conversion in
 * pymssql as well as the parameter handling of the procedures.
 */

/* Exact Numeric Types */
CREATE PROCEDURE [dbo].[pymssqlTestBigInt]
    @ibigint bigint,
    @obigint bigint output
AS
BEGIN
    SET @obigint = @ibigint;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestBit]
    @ibit bit,
    @obit bit output
AS
BEGIN
    SET @obit = @ibit;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestDecimal]
    @idecimal decimal(6, 5),
    @odecimal decimal(6, 5) output
AS
BEGIN
    SET @odecimal = @idecimal;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestInt]
    @iint int,
    @oint int output
AS
BEGIN
    SET @oint = @iint;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestMoney]
    @imoney money,
    @omoney money output
AS
BEGIN
    SET @omoney = @imoney;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestNumeric]
    @inumeric numeric,
    @onumeric numeric output
AS
BEGIN
    SET @onumeric = @inumeric;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestSmallInt]
    @ismallint smallint,
    @osmallint smallint output
AS
BEGIN
    SET @osmallint = @ismallint;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestSmallMoney]
    @ismallmoney smallmoney,
    @osmallmoney smallmoney output
AS
BEGIN
    SET @osmallmoney = @ismallmoney;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestTinyInt]
    @itinyint tinyint,
    @otinyint tinyint output
AS
BEGIN
    SET @otinyint = @itinyint;
    RETURN 0;
END

--SPLIT

/* Approximate Numerics */
CREATE PROCEDURE [dbo].[pymssqlTestFloat]
    @ifloat float,
    @ofloat float output
AS
BEGIN
    SET @ofloat = @ifloat;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestReal]
    @ireal real,
    @oreal real output
AS
BEGIN
    SET @oreal = @ireal;
    RETURN 0;
END

/* Date and Time types */
--set ANSI_NULLS ON
--set QUOTED_IDENTIFIER ON
--
--CREATE PROCEDURE [dbo].[pymssqlTestDate]
--    @idate date,
--    @odate date output
--AS
--BEGIN
--    SET @odate = @idate;
--    RETURN 0;
--END
--

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestDateTime]
    @idatetime datetime,
    @odatetime datetime output
AS
BEGIN
    SET @odatetime = @idatetime;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestDateTime2]
    @idatetime2 datetime,
    @odatetime2 datetime output
AS
BEGIN
    SET @odatetime2 = @idatetime2;
    RETURN 0;
END

--set ANSI_NULLS ON
--set QUOTED_IDENTIFIER ON
--GO
--CREATE PROCEDURE [dbo].[pymssqlTestDateTimeOffset]
--    @idatetimeoffset datetimeoffset,
--    @odatetimeoffset datetimeoffset output
--AS
--BEGIN
--    SET @odatetimeoffset = @idatetimeoffset;
--    RETURN 0;
--END
--
--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestSmallDateTime]
    @ismalldatetime smalldatetime,
    @osmalldatetime smalldatetime output
AS
BEGIN
    SET @osmalldatetime = @ismalldatetime;
    RETURN 0;
END

--SPLIT

/* Character Strings */
CREATE PROCEDURE [dbo].[pymssqlTestChar]
    @ichar char(4),
    @ochar char(4) output
AS
BEGIN
    SET @ochar = @ichar;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestText]
    @itext text,
    @otext varchar(255) output
AS
BEGIN
    SET @otext = @itext;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestVarChar]
    @ivarchar varchar(4),
    @ovarchar varchar(4) output
AS
BEGIN
    SET @ovarchar = @ivarchar;
    RETURN 0;
END

--SPLIT

/* Unicode Character Strings */
CREATE PROCEDURE [dbo].[pymssqlTestNChar]
    @inchar nchar,
    @onchar nchar output
AS
BEGIN
    SET @onchar = @inchar;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestNText]
    @intext ntext,
    @ontext ntext output
AS
BEGIN
    SET @ontext = @intext;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestNVarChar]
    @invarchar nvarchar,
    @onvarchar nvarchar output
AS
BEGIN
    SET @onvarchar = @invarchar;
    RETURN 0;
END

--SPLIT

/* Binary Strings */
CREATE PROCEDURE [dbo].[pymssqlTestBinary]
    @ibinary binary,
    @obinary binary output
AS
BEGIN
    SET @obinary = @ibinary;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlTestImage]
    @iimage image,
    @oimage image output
AS
BEGIN
    SET @oimage = @iimage;
    RETURN 0;
END

--SPLIT

CREATE PROCEDURE [dbo].[pymssqlVarBinary]
    @ivarbinary varbinary,
    @ovarbinary varbinary output
AS
BEGIN
    SET @ovarbinary = @ivarbinary;
    RETURN 0;
END
