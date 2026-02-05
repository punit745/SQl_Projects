@echo off
REM ================================================================
REM Run SQL Query Script for Windows
REM Execute a SQL file and display results
REM ================================================================

REM Configuration
SET DB_NAME=retail_sales_advanced
SET MYSQL_USER=root

echo ========================================
echo SQL Query Runner
echo ========================================
echo.

IF "%1"=="" (
    echo Usage: run_query.bat ^<sql_file^>
    echo Example: run_query.bat ..\queries\09_advanced_analytics.sql
    echo.
    pause
    exit /b 1
)

SET SQL_FILE=%1

IF NOT EXIST %SQL_FILE% (
    echo ERROR: File not found: %SQL_FILE%
    pause
    exit /b 1
)

echo Database: %DB_NAME%
echo SQL File: %SQL_FILE%
echo.

SET /P MYSQL_PASSWORD=Enter MySQL password for %MYSQL_USER%: 

echo.
echo Executing query...
echo ========================================
echo.

mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% %DB_NAME% < %SQL_FILE%

echo.
echo ========================================
echo Query execution completed.
echo ========================================
pause
