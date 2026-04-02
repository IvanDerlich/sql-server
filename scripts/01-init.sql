-- ============================================================================
-- DATABASE INITIALIZATION SCRIPT
-- Purpose: Set up application database, login, user, and schema
-- Note: This script is idempotent and can be run multiple times safely
-- Variables: $(APP_DB_NAME), $(APP_DB_USER), $(APP_DB_PASSWORD)
-- ============================================================================

-- SECTION 1: CREATE DATABASE IF NOT EXISTS
-- Check if the database already exists using DB_ID() system function
-- If database does not exist (DB_ID returns NULL), create it dynamically
-- N'...': Unicode string literal in SQL Server; used when building NVARCHAR dynamic SQL
IF DB_ID('$(APP_DB_NAME)') IS NULL
BEGIN
    DECLARE @createDb NVARCHAR(MAX) = N'CREATE DATABASE [' + REPLACE('$(APP_DB_NAME)', ']', ']]') + N']';
    EXEC (@createDb);
END;
GO

-- SECTION 2: CREATE LOGIN IF NOT EXISTS
-- Check sys.sql_logins to see if the application user login already exists
-- sys.sql_logins is a SQL Server system catalog view in the sys schema (server-level metadata)
-- We query it because LOGIN is a server object, not a database-local object
-- Login is server-level authentication credential
-- Password validation: CHECK_POLICY=ON enforces complexity, CHECK_EXPIRATION=OFF disables expiry
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = '$(APP_DB_USER)')
BEGIN
    DECLARE @createLogin NVARCHAR(MAX) =
        N'CREATE LOGIN [' + REPLACE('$(APP_DB_USER)', ']', ']]') + N'] WITH PASSWORD = ''' +
        REPLACE('$(APP_DB_PASSWORD)', '''', '''''') + N''', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF';
    EXEC (@createLogin);
END;
GO

-- SECTION 3: SWITCH TO APPLICATION DATABASE CONTEXT
-- Dynamic SQL needed because USE statement cannot appear in conditional blocks
-- This ensures all subsequent commands (user creation, table creation) target the correct database
DECLARE @useDb NVARCHAR(MAX) = N'USE [' + REPLACE('$(APP_DB_NAME)', ']', ']]') + N']';
EXEC (@useDb);
GO

-- SECTION 4: CREATE DATABASE USER FROM LOGIN
-- Create database-level user that maps to the server-level login created in SECTION 2
-- User provides database-level permissions and role membership
-- Check sys.database_principals to ensure user doesn't already exist
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$(APP_DB_USER)')
BEGIN
    DECLARE @createUser NVARCHAR(MAX) =
        N'CREATE USER [' + REPLACE('$(APP_DB_USER)', ']', ']]') + N'] FOR LOGIN [' +
        REPLACE('$(APP_DB_USER)', ']', ']]') + N']';
    EXEC (@createUser);
END;
GO

-- SECTION 5: ASSIGN db_datareader ROLE (SELECT permissions)
-- Grants SELECT (read) permissions on all tables, views, and stored procedures
-- TRY/CATCH wraps this in error handling because role member addition may fail if already assigned
-- Silently catching errors ensures idempotency (no error on second run)
DECLARE @addReader NVARCHAR(MAX) =
    N'ALTER ROLE [db_datareader] ADD MEMBER [' + REPLACE('$(APP_DB_USER)', ']', ']]') + N']';
BEGIN TRY
    EXEC (@addReader);
END TRY
BEGIN CATCH
    -- Silently ignore error if user is already a member of this role
END CATCH;
GO

-- SECTION 6: ASSIGN db_datawriter ROLE (INSERT, UPDATE, DELETE permissions)
-- Grants INSERT, UPDATE, DELETE permissions on all tables
-- Combined with db_datareader role from SECTION 5, user now has full read/write access
-- TRY/CATCH for idempotency (same reasoning as SECTION 5)
DECLARE @addWriter NVARCHAR(MAX) =
    N'ALTER ROLE [db_datawriter] ADD MEMBER [' + REPLACE('$(APP_DB_USER)', ']', ']]') + N']';
BEGIN TRY
    EXEC (@addWriter);
END TRY
BEGIN CATCH
    -- Silently ignore error if user is already a member of this role
END CATCH;
GO

-- SECTION 7: CREATE APPLICATION TABLE (if not exists)
-- Check OBJECT_ID() to verify table dbo.app_items does not already exist
-- Table schema:
--   - id: INT IDENTITY(1,1) - Auto-incrementing primary key starting at 1
--   - name: NVARCHAR(100) NOT NULL - Product/item name, fixed max length
--   - quantity: INT NOT NULL - Item quantity in stock, must be an integer
-- This table will be populated by 02-seed.sql script
IF OBJECT_ID('dbo.app_items', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.app_items (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        quantity INT NOT NULL
    );
END;
GO
