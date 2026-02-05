@echo off
REM ================================================================
REM DATABASE MIGRATION RUNNER
REM Applies pending database migrations
REM ================================================================

setlocal enabledelayedexpansion

REM Database credentials
set DB_HOST=localhost
set DB_USER=root
set DB_NAME=retail_sales_advanced

REM Colors for output
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "NC=[0m"

echo.
echo ========================================
echo   Database Migration Runner
echo ========================================
echo.

REM Check if mysql is available
where mysql >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%ERROR: MySQL client not found in PATH%NC%
    echo Please install MySQL or add it to PATH
    exit /b 1
)

REM Get the directory of this script
set SCRIPT_DIR=%~dp0
set MIGRATION_DIR=%SCRIPT_DIR%..\migrations

REM Check if migrations directory exists
if not exist "%MIGRATION_DIR%" (
    echo %YELLOW%WARNING: Migrations directory not found%NC%
    echo Creating: %MIGRATION_DIR%
    mkdir "%MIGRATION_DIR%"
)

echo %YELLOW%Checking for pending migrations...%NC%
echo.

REM Run the migration file
if exist "%MIGRATION_DIR%\v1_to_v2.sql" (
    echo Running: v1_to_v2.sql
    
    set /p DB_PASS=Enter MySQL password: 
    
    mysql -h %DB_HOST% -u %DB_USER% -p!DB_PASS! %DB_NAME% < "%MIGRATION_DIR%\v1_to_v2.sql"
    
    if !errorlevel! equ 0 (
        echo %GREEN%Migration completed successfully%NC%
    ) else (
        echo %RED%Migration failed%NC%
        exit /b 1
    )
) else (
    echo %YELLOW%No migration files found%NC%
)

echo.
echo ========================================
echo   Applying all migrations...
echo ========================================

REM Apply all migrations via stored procedure
mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% -e "CALL apply_all_migrations();"

echo.
echo %GREEN%Migration process complete%NC%
echo.

REM Show migration status
echo Current migration status:
mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% -e "SELECT * FROM vw_migration_status;" 2>nul

endlocal
