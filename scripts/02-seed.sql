-- ============================================================================
-- SEED DATA INITIALIZATION SCRIPT
-- Purpose: Populate dbo.app_items table with initial reference data
-- Note: This script is idempotent and can be run multiple times safely
-- ============================================================================

-- Set the database context to the application database
-- $(APP_DB_NAME) is substituted via sqlcmd -v parameter at runtime
USE [$(APP_DB_NAME)];
GO

-- Idempotency check: Only insert seed data if the table is empty
-- This prevents duplicate data insertion on subsequent runs
-- Wrapped in IF NOT EXISTS to ensure one-time population
IF NOT EXISTS (SELECT 1 FROM dbo.app_items)
BEGIN
    -- Insert three rows of seed data into the app_items table
    -- Columns: name (NVARCHAR(100)), quantity (INT)
    -- Note: id column uses IDENTITY and auto-increments, so it's not specified here
    INSERT INTO dbo.app_items (name, quantity)
    VALUES
        ('Notebook', 10),    -- Item #1: 10 notebooks in stock
        ('Mouse', 25),       -- Item #2: 25 mice in stock
        ('Keyboard', 15);    -- Item #3: 15 keyboards in stock
END;
GO

-- Batch separator (GO) ensures all statements are executed
