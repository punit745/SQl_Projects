@echo off
REM ================================================================
REM Database Setup Script for Windows
REM Runs all schema creation scripts in order
REM ================================================================

REM Configuration
SET MYSQL_USER=root
SET SCHEMA_DIR=..\schema
SET DATA_DIR=..\data

echo ========================================
echo Database Setup Script
echo ========================================
echo.
echo This script will:
echo 1. Create the database
echo 2. Create all tables
echo 3. Create indexes
echo 4. Create views
echo 5. Create stored procedures
echo 6. Create functions
echo 7. Create triggers
echo 8. Load seed data
echo.

SET /P MYSQL_PASSWORD=Enter MySQL password for %MYSQL_USER%: 

echo.
echo Step 1: Creating database...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\01_create_database.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 2: Creating tables...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\02_create_tables.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 3: Creating indexes...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\03_create_indexes.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 4: Creating views...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\04_create_views.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 5: Creating stored procedures...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\05_create_procedures.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 6: Creating functions...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\06_create_functions.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 7: Creating triggers...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %SCHEMA_DIR%\07_create_triggers.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo Step 8: Loading seed data...
mysql -u %MYSQL_USER% -p%MYSQL_PASSWORD% < %DATA_DIR%\seed_data.sql
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

echo.
echo ========================================
echo Database setup completed successfully!
echo ========================================
GOTO END

:ERROR
echo.
echo ========================================
echo ERROR: Setup failed at the last step!
echo Please check the error messages above.
echo ========================================

:END
echo.
pause
