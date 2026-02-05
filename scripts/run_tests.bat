@echo off
REM ================================================================
REM RUN ALL TESTS
REM Execute SQL testing framework
REM ================================================================

setlocal enabledelayedexpansion

set DB_HOST=localhost
set DB_USER=root
set DB_NAME=retail_sales_advanced

echo.
echo ========================================
echo   SQL Testing Framework
echo ========================================
echo.

set /p DB_PASS=Enter MySQL password: 

REM Run test files
echo.
echo Loading test framework...
mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "%~dp0..\tests\test_procedures.sql"

echo.
echo Loading trigger tests...
mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "%~dp0..\tests\test_triggers.sql"

echo.
echo Loading data integrity tests...
mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% < "%~dp0..\tests\test_data_integrity.sql"

echo.
echo ========================================
echo   Running All Tests...
echo ========================================
echo.

mysql -h %DB_HOST% -u %DB_USER% -p%DB_PASS% %DB_NAME% -e "CALL run_all_tests();"

echo.
echo Test execution complete!
echo.

endlocal
