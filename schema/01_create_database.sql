-- ================================================================
-- DATABASE CREATION SCRIPT
-- Creates the retail_sales_advanced database
-- ================================================================

-- Drop existing database if it exists (use with caution!)
DROP DATABASE IF EXISTS retail_sales_advanced;

-- Create the database
CREATE DATABASE retail_sales_advanced
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Select the database
USE retail_sales_advanced;

-- Verify database creation
SELECT 'Database retail_sales_advanced created successfully!' AS status;
