@echo off
REM ================================================================
REM Database Backup Script for Windows
REM Creates timestamped backup of the retail_sales_advanced database
REM ================================================================

REM Configuration
SET DB_NAME=retail_sales_advanced
SET BACKUP_DIR=backups
SET MYSQL_USER=root
SET TIMESTAMP=%DATE:~-4,4%%DATE:~-10,2%%DATE:~-7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
SET TIMESTAMP=%TIMESTAMP: =0%

REM Create backup directory if it doesn't exist
IF NOT EXIST %BACKUP_DIR% mkdir %BACKUP_DIR%

REM Create backup filename
SET BACKUP_FILE=%BACKUP_DIR%\%DB_NAME%_%TIMESTAMP%.sql

echo ========================================
echo Database Backup Script
echo ========================================
echo.
echo Database: %DB_NAME%
echo Backup File: %BACKUP_FILE%
echo.

REM Prompt for password
SET /P MYSQL_PASSWORD=Enter MySQL password for %MYSQL_USER%: 

REM Run mysqldump
echo.
echo Creating backup...
mysqldump -u %MYSQL_USER% -p%MYSQL_PASSWORD% --routines --triggers --events %DB_NAME% > %BACKUP_FILE%

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Backup completed successfully!
    echo File: %BACKUP_FILE%
    echo Size: 
    for %%A in ("%BACKUP_FILE%") do echo %%~zA bytes
    echo ========================================
) ELSE (
    echo.
    echo ERROR: Backup failed!
    del %BACKUP_FILE% 2>nul
)

echo.
pause
