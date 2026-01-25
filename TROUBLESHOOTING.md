# 🔧 Troubleshooting Guide

Common issues and solutions when working with this SQL project.

---

## Installation Issues

### MySQL Installation Problems

#### Issue: Can't install MySQL Server

**Windows:**
```bash
# Download MySQL Installer from official website
# Run as Administrator
# Select "Developer Default" or "Server only"
```

**macOS:**
```bash
# If Homebrew installation fails
brew update
brew doctor
brew install mysql

# Start MySQL
brew services start mysql
```

**Linux (Ubuntu/Debian):**
```bash
# If apt install fails
sudo apt update
sudo apt upgrade
sudo apt install mysql-server mysql-client

# Start MySQL service
sudo systemctl start mysql
sudo systemctl enable mysql
```

#### Issue: MySQL service won't start

**Solution:**
```bash
# Check MySQL error log
# Linux
sudo tail -f /var/log/mysql/error.log

# macOS
tail -f /usr/local/var/mysql/*.err

# Windows
# Check: C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err
```

Common fixes:
- Check if port 3306 is already in use
- Ensure proper file permissions on data directory
- Check for disk space issues

---

## Connection Issues

### Issue: Can't connect to MySQL server

**Error:** `ERROR 2003 (HY000): Can't connect to MySQL server on 'localhost'`

**Solutions:**

1. **Check if MySQL is running:**
```bash
# Linux/macOS
sudo systemctl status mysql
# or
ps aux | grep mysql

# Windows
# Check Services panel for "MySQL" service
```

2. **Verify connection parameters:**
```sql
mysql -u root -p
# Enter password when prompted
```

3. **Check MySQL is listening on correct port:**
```bash
netstat -an | grep 3306
```

### Issue: Access denied for user

**Error:** `ERROR 1045 (28000): Access denied for user 'root'@'localhost'`

**Solutions:**

1. **Reset root password:**
```bash
# Stop MySQL
sudo systemctl stop mysql

# Start in safe mode
sudo mysqld_safe --skip-grant-tables &

# Connect and reset password
mysql -u root
```

```sql
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
exit;
```

```bash
# Restart MySQL normally
sudo systemctl restart mysql
```

2. **Create new user with proper privileges:**
```sql
CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON retail_sales_advanced.* TO 'newuser'@'localhost';
FLUSH PRIVILEGES;
```

---

## SQL Script Execution Issues

### Issue: Syntax errors when running Advanced_SQL_Queries.sql

**Error:** `ERROR 1064 (42000): You have an error in your SQL syntax`

**Solutions:**

1. **Check MySQL version:**
```sql
SELECT VERSION();
-- Should be 8.0 or higher
```

2. **Run sections separately:**
- Execute sections 1-2 first (schema and data)
- Then execute other sections individually
- Some clients have issues with large scripts

3. **Check DELIMITER settings:**
```sql
-- Ensure DELIMITER is reset
DELIMITER ;
```

4. **Use MySQL Workbench:**
- Better error reporting than command line
- Can execute scripts section by section

### Issue: "Table already exists" error

**Error:** `ERROR 1050 (42S01): Table 'products' already exists`

**Solution:**
```sql
-- Drop database and start fresh
DROP DATABASE IF EXISTS retail_sales_advanced;
-- Then run the script again
```

### Issue: Foreign key constraint fails

**Error:** `ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails`

**Solutions:**

1. **Ensure parent records exist first:**
```sql
-- Insert categories before products
-- Insert customers before sales
```

2. **Check foreign key references:**
```sql
-- View foreign key constraints
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
    AND REFERENCED_TABLE_NAME IS NOT NULL;
```

3. **Temporarily disable foreign key checks (careful!):**
```sql
SET FOREIGN_KEY_CHECKS = 0;
-- Your INSERT statements
SET FOREIGN_KEY_CHECKS = 1;
```

---

## Query Performance Issues

### Issue: Queries running very slowly

**Solutions:**

1. **Use EXPLAIN to analyze:**
```sql
EXPLAIN SELECT * FROM sales WHERE customer_id = 1;
-- Look for "Using filesort", "Using temporary", or "ALL" in type column
```

2. **Add missing indexes:**
```sql
-- Check existing indexes
SHOW INDEX FROM sales;

-- Add index if needed
CREATE INDEX idx_customer ON sales(customer_id);
```

3. **Optimize query structure:**
```sql
-- Bad: Function on indexed column
SELECT * FROM customers WHERE UPPER(email) = 'TEST@EMAIL.COM';

-- Good: Use column directly
SELECT * FROM customers WHERE email = 'test@email.com';
```

4. **Limit result sets:**
```sql
-- Add LIMIT for large tables
SELECT * FROM sales 
WHERE sale_date >= '2024-01-01'
LIMIT 100;
```

### Issue: Out of memory errors

**Error:** `ERROR 1038 (HY001): Out of sort memory`

**Solutions:**

1. **Increase sort buffer:**
```sql
SET SESSION sort_buffer_size = 256 * 1024 * 1024;  -- 256MB
```

2. **Use more efficient queries:**
```sql
-- Instead of sorting entire table
SELECT * FROM sales ORDER BY sale_date DESC LIMIT 10;

-- Use index-based queries
SELECT * FROM sales USE INDEX (idx_date) 
WHERE sale_date >= '2024-01-01';
```

---

## Stored Procedure Issues

### Issue: Stored procedure won't execute

**Error:** `ERROR 1305 (42000): PROCEDURE does not exist`

**Solutions:**

1. **Check if procedure exists:**
```sql
SHOW PROCEDURE STATUS WHERE Db = 'retail_sales_advanced';
```

2. **Ensure using correct database:**
```sql
USE retail_sales_advanced;
CALL sp_add_sale(1, 2, 2, 3, 1);
```

3. **Recreate the procedure:**
```sql
DROP PROCEDURE IF EXISTS sp_add_sale;
-- Then run the CREATE PROCEDURE statement again
```

### Issue: Delimiter issues in stored procedures

**Solution:**

In MySQL Workbench:
- Select the entire procedure code including DELIMITER statements
- Execute as a single block

In command line:
```bash
mysql -u root -p retail_sales_advanced < procedure_file.sql
```

---

## Trigger Issues

### Issue: Trigger not firing

**Solutions:**

1. **Check if trigger exists:**
```sql
SHOW TRIGGERS FROM retail_sales_advanced;
```

2. **Verify trigger timing:**
```sql
-- Check if trigger is BEFORE or AFTER
-- Ensure it matches your needs
```

3. **Check for errors in trigger logic:**
```sql
-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trg_update_customer_spending;
-- Then recreate with corrected logic
```

### Issue: Trigger causes error on INSERT

**Error:** `ERROR 1644 (45000): [Custom error message]`

**Solution:**
- This is likely a SIGNAL statement in the trigger
- Check trigger logic to understand the business rule being enforced
- Either fix the data or modify the trigger

---

## View Issues

### Issue: View returns unexpected results

**Solutions:**

1. **Check view definition:**
```sql
SHOW CREATE VIEW vw_sales_summary;
```

2. **Drop and recreate view:**
```sql
DROP VIEW IF EXISTS vw_sales_summary;
CREATE VIEW vw_sales_summary AS
-- Your SELECT statement
```

3. **Test underlying query:**
- Copy the SELECT statement from view
- Run it directly to debug

---

## Data Issues

### Issue: No data returned from queries

**Solutions:**

1. **Verify data exists:**
```sql
SELECT COUNT(*) FROM sales;
SELECT COUNT(*) FROM customers;
```

2. **Check WHERE clause:**
```sql
-- Remove WHERE clause temporarily
SELECT * FROM sales;
-- Then add filters back one by one
```

3. **Reload sample data:**
```sql
-- Re-run sections 2 of Advanced_SQL_Queries.sql
-- This inserts sample data
```

### Issue: Duplicate data in results

**Solutions:**

1. **Use DISTINCT:**
```sql
SELECT DISTINCT customer_id, name FROM customers;
```

2. **Check for duplicate JOIN conditions:**
```sql
-- Ensure proper JOIN conditions
SELECT c.*, s.*
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id;
```

---

## Python Integration Issues (SQL_Project.ipynb)

### Issue: Can't connect from Python

**Error:** `mysql.connector.errors.InterfaceError`

**Solutions:**

1. **Install MySQL connector:**
```bash
pip install mysql-connector-python
```

2. **Update connection parameters:**
```python
connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="your_password",
    database="retail_sales_advanced"
)
```

3. **Check firewall settings:**
- Ensure MySQL port 3306 is open
- Check if localhost resolves correctly

---

## General Tips

### Best Practices for Troubleshooting

1. **Start simple:**
   - Test basic SELECT queries first
   - Add complexity gradually

2. **Check error messages carefully:**
   - Error code often indicates the issue
   - Google the exact error code

3. **Use MySQL error log:**
```bash
# Find MySQL error log
mysql -u root -p -e "SHOW VARIABLES LIKE 'log_error';"
```

4. **Test in isolation:**
   - Create a test database
   - Test problematic queries separately

5. **Version compatibility:**
```sql
-- Check MySQL version
SELECT VERSION();

-- Some features require MySQL 8.0+
-- Window functions, CTEs, etc.
```

### Useful Commands for Debugging

```sql
-- Show all databases
SHOW DATABASES;

-- Show all tables in current database
SHOW TABLES;

-- Describe table structure
DESCRIBE products;
SHOW CREATE TABLE products;

-- Show current database
SELECT DATABASE();

-- Show current user
SELECT USER();

-- Show all processes
SHOW PROCESSLIST;

-- Show engine status
SHOW ENGINE INNODB STATUS;

-- Show table statistics
SHOW TABLE STATUS;
```

---

## Getting Help

If you still have issues:

1. **Check existing documentation:**
   - README.md
   - SQL_CONCEPTS_GUIDE.md
   - QUICK_START.md

2. **Search for similar issues:**
   - GitHub Issues in this repository
   - Stack Overflow with [mysql] tag

3. **Create a new issue:**
   - Include MySQL version
   - Include exact error message
   - Include steps to reproduce
   - Include relevant code snippets

4. **Community resources:**
   - MySQL Forums
   - Stack Overflow
   - Reddit r/mysql

---

## Appendix: Common Error Codes

| Error Code | Description | Common Cause |
|------------|-------------|--------------|
| 1045 | Access denied | Wrong password or user |
| 1046 | No database selected | Missing USE statement |
| 1050 | Table already exists | Duplicate CREATE TABLE |
| 1054 | Unknown column | Typo in column name |
| 1062 | Duplicate entry | Unique constraint violation |
| 1064 | Syntax error | SQL syntax mistake |
| 1146 | Table doesn't exist | Wrong table name or database |
| 1215 | Cannot add foreign key | Referenced table/column missing |
| 1305 | Procedure doesn't exist | Wrong procedure name or database |
| 1452 | Foreign key constraint fails | Referencing non-existent parent |
| 2003 | Can't connect to server | MySQL not running or wrong host |
| 2006 | MySQL server has gone away | Connection timeout or packet size |

---

<div align="center">

**Still stuck? Open an issue on GitHub!**

We're here to help! 🚀

</div>
