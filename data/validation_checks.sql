-- ================================================================
-- DATA VALIDATION AND INTEGRITY CHECKS
-- Queries to verify data quality and consistency
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: REFERENTIAL INTEGRITY CHECKS
-- ================================================================

-- Check for orphaned sales (customer doesn't exist)
SELECT 'Orphaned Sales (missing customer)' AS check_type, 
       COUNT(*) AS issue_count
FROM sales s
LEFT JOIN customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for orphaned sales_details (sale doesn't exist)
SELECT 'Orphaned Sales Details (missing sale)' AS check_type,
       COUNT(*) AS issue_count
FROM sales_details sd
LEFT JOIN sales s ON sd.sale_id = s.sale_id
WHERE s.sale_id IS NULL;

-- Check for orphaned sales_details (product doesn't exist)
SELECT 'Orphaned Sales Details (missing product)' AS check_type,
       COUNT(*) AS issue_count
FROM sales_details sd
LEFT JOIN products p ON sd.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check for orphaned products (category doesn't exist)
SELECT 'Orphaned Products (missing category)' AS check_type,
       COUNT(*) AS issue_count
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE p.category_id IS NOT NULL AND c.category_id IS NULL;

-- Check for customers with invalid tier
SELECT 'Customers with Invalid Tier' AS check_type,
       COUNT(*) AS issue_count
FROM customers c
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
WHERE c.tier_id IS NOT NULL AND ct.tier_id IS NULL;

-- Check for employees with invalid manager
SELECT 'Employees with Invalid Manager' AS check_type,
       COUNT(*) AS issue_count
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
WHERE e.manager_id IS NOT NULL AND m.employee_id IS NULL;

-- ================================================================
-- SECTION 2: DATA CONSISTENCY CHECKS
-- ================================================================

-- Sales with mismatched totals
SELECT 'Sales with Calculation Errors' AS check_type,
       COUNT(*) AS issue_count
FROM sales
WHERE ABS((subtotal - discount_amount + tax_amount) - total_amount) > 1;

-- Show the actual mismatched sales
SELECT 
    sale_id,
    subtotal,
    discount_amount,
    tax_amount,
    total_amount,
    (subtotal - discount_amount + tax_amount) AS calculated_total,
    ABS((subtotal - discount_amount + tax_amount) - total_amount) AS difference
FROM sales
WHERE ABS((subtotal - discount_amount + tax_amount) - total_amount) > 1
LIMIT 10;

-- Sales details with incorrect line totals
SELECT 'Sales Details with Calculation Errors' AS check_type,
       COUNT(*) AS issue_count
FROM sales_details
WHERE ABS((unit_price * quantity * (1 - COALESCE(discount, 0)/100)) - line_total) > 1;

-- Check for negative amounts
SELECT 'Sales with Negative Amounts' AS check_type,
       COUNT(*) AS issue_count
FROM sales
WHERE total_amount < 0 OR subtotal < 0 OR tax_amount < 0;

-- Check for zero or negative quantities
SELECT 'Sales Details with Invalid Quantities' AS check_type,
       COUNT(*) AS issue_count
FROM sales_details
WHERE quantity <= 0;

-- Check for negative prices
SELECT 'Products with Negative Prices' AS check_type,
       COUNT(*) AS issue_count
FROM products
WHERE price < 0 OR cost_price < 0;

-- Check for negative stock
SELECT 'Products with Negative Stock' AS check_type,
       COUNT(*) AS issue_count
FROM products
WHERE stock < 0;

-- ================================================================
-- SECTION 3: DUPLICATE DETECTION
-- ================================================================

-- Duplicate customer emails
SELECT 'Duplicate Customer Emails' AS check_type,
       email,
       COUNT(*) AS duplicate_count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

-- Duplicate product SKUs
SELECT 'Duplicate Product SKUs' AS check_type,
       sku,
       COUNT(*) AS duplicate_count
FROM products
WHERE sku IS NOT NULL
GROUP BY sku
HAVING COUNT(*) > 1;

-- Duplicate employee emails
SELECT 'Duplicate Employee Emails' AS check_type,
       email,
       COUNT(*) AS duplicate_count
FROM employees
GROUP BY email
HAVING COUNT(*) > 1;

-- Potential duplicate customers (same name and city)
SELECT 'Potential Duplicate Customers' AS check_type,
       name, city,
       COUNT(*) AS duplicate_count,
       GROUP_CONCAT(customer_id) AS customer_ids
FROM customers
GROUP BY name, city
HAVING COUNT(*) > 1;

-- ================================================================
-- SECTION 4: NULL VALUE CHECKS
-- ================================================================

-- Required fields that are NULL
SELECT 'Customers with NULL Names' AS check_type, COUNT(*) AS issue_count
FROM customers WHERE name IS NULL OR name = '';

SELECT 'Customers with NULL Emails' AS check_type, COUNT(*) AS issue_count
FROM customers WHERE email IS NULL OR email = '';

SELECT 'Products with NULL Names' AS check_type, COUNT(*) AS issue_count
FROM products WHERE name IS NULL OR name = '';

SELECT 'Products with NULL Prices' AS check_type, COUNT(*) AS issue_count
FROM products WHERE price IS NULL;

SELECT 'Sales with NULL Total Amount' AS check_type, COUNT(*) AS issue_count
FROM sales WHERE total_amount IS NULL;

-- ================================================================
-- SECTION 5: RANGE AND FORMAT CHECKS
-- ================================================================

-- Invalid email formats
SELECT 'Customers with Invalid Email Format' AS check_type,
       COUNT(*) AS issue_count
FROM customers
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

-- Invalid phone formats (should be 10 digits for India)
SELECT 'Customers with Invalid Phone Format' AS check_type,
       COUNT(*) AS issue_count
FROM customers
WHERE phone IS NOT NULL 
  AND phone NOT REGEXP '^[0-9]{10}$';

-- Future dates in sales
SELECT 'Sales with Future Dates' AS check_type,
       COUNT(*) AS issue_count
FROM sales
WHERE sale_date > NOW();

-- Registration dates in the future
SELECT 'Customers with Future Registration Dates' AS check_type,
       COUNT(*) AS issue_count
FROM customers
WHERE registration_date > CURRENT_DATE;

-- Prices outside reasonable range
SELECT 'Products with Suspicious Prices' AS check_type,
       COUNT(*) AS issue_count
FROM products
WHERE price < 100 OR price > 10000000;

-- ================================================================
-- SECTION 6: BUSINESS LOGIC VALIDATION
-- ================================================================

-- Cost price higher than selling price
SELECT 'Products with Cost > Selling Price' AS check_type,
       product_id, name, price, cost_price
FROM products
WHERE cost_price > price
LIMIT 10;

-- Customers with total_spent mismatch
SELECT 'Customers with Incorrect Total Spent' AS check_type,
       c.customer_id,
       c.name,
       c.total_spent AS recorded_total,
       COALESCE(SUM(s.total_amount), 0) AS calculated_total,
       ABS(c.total_spent - COALESCE(SUM(s.total_amount), 0)) AS difference
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
GROUP BY c.customer_id, c.name, c.total_spent
HAVING ABS(c.total_spent - COALESCE(SUM(s.total_amount), 0)) > 1
LIMIT 10;

-- Sales with discount higher than subtotal
SELECT 'Sales with Discount > Subtotal' AS check_type,
       COUNT(*) AS issue_count
FROM sales
WHERE discount_amount > subtotal;

-- Customer tier doesn't match spending level
SELECT 'Customers with Incorrect Tier' AS check_type,
       c.customer_id,
       c.name,
       c.total_spent,
       ct.tier_name AS current_tier,
       (SELECT tier_name FROM customer_tiers 
        WHERE c.total_spent >= min_purchases 
        ORDER BY min_purchases DESC LIMIT 1) AS correct_tier
FROM customers c
JOIN customer_tiers ct ON c.tier_id = ct.tier_id
WHERE c.tier_id != (
    SELECT tier_id FROM customer_tiers 
    WHERE c.total_spent >= min_purchases 
    ORDER BY min_purchases DESC LIMIT 1
)
LIMIT 10;

-- ================================================================
-- SECTION 7: DATA QUALITY SUMMARY
-- ================================================================

-- Comprehensive data quality report
SELECT 'DATA QUALITY SUMMARY' AS report_section;

SELECT 
    'customers' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN email IS NULL OR email = '' THEN 1 ELSE 0 END) AS null_emails,
    COUNT(*) - COUNT(DISTINCT email) AS duplicate_emails
FROM customers

UNION ALL

SELECT 
    'products' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS null_names,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN stock < 0 THEN 1 ELSE 0 END) AS negative_stock
FROM products

UNION ALL

SELECT 
    'sales' AS table_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS null_totals,
    SUM(CASE WHEN total_amount < 0 THEN 1 ELSE 0 END) AS negative_totals,
    SUM(CASE WHEN sale_date > NOW() THEN 1 ELSE 0 END) AS future_dates
FROM sales;

-- ================================================================
-- SECTION 8: FIX PROCEDURES (USE WITH CAUTION)
-- ================================================================

-- Procedure to recalculate customer total_spent
DELIMITER //
CREATE PROCEDURE sp_fix_customer_totals()
BEGIN
    UPDATE customers c
    SET total_spent = (
        SELECT COALESCE(SUM(s.total_amount), 0)
        FROM sales s
        WHERE s.customer_id = c.customer_id
          AND s.status = 'completed'
    );
    
    SELECT 'Customer totals recalculated' AS status,
           ROW_COUNT() AS customers_updated;
END //
DELIMITER ;

-- Procedure to recalculate sales line totals
DELIMITER //
CREATE PROCEDURE sp_fix_sales_line_totals()
BEGIN
    UPDATE sales_details
    SET line_total = unit_price * quantity * (1 - COALESCE(discount, 0)/100);
    
    SELECT 'Sales line totals recalculated' AS status,
           ROW_COUNT() AS records_updated;
END //
DELIMITER ;

-- Procedure to update customer tiers based on spending
DELIMITER //
CREATE PROCEDURE sp_fix_customer_tiers()
BEGIN
    UPDATE customers c
    SET tier_id = (
        SELECT tier_id 
        FROM customer_tiers 
        WHERE c.total_spent >= min_purchases 
        ORDER BY min_purchases DESC 
        LIMIT 1
    );
    
    SELECT 'Customer tiers updated' AS status,
           ROW_COUNT() AS customers_updated;
END //
DELIMITER ;

-- ================================================================
-- SECTION 9: VALIDATION STORED PROCEDURE
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_run_all_validations()
BEGIN
    -- Create temp table for results
    CREATE TEMPORARY TABLE IF NOT EXISTS validation_results (
        check_name VARCHAR(100),
        issue_count INT,
        check_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    TRUNCATE TABLE validation_results;
    
    -- Run all checks
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Orphaned Sales', COUNT(*) FROM sales s
    LEFT JOIN customers c ON s.customer_id = c.customer_id WHERE c.customer_id IS NULL;
    
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Orphaned Sales Details', COUNT(*) FROM sales_details sd
    LEFT JOIN sales s ON sd.sale_id = s.sale_id WHERE s.sale_id IS NULL;
    
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Sales with Calculation Errors', COUNT(*) FROM sales
    WHERE ABS((subtotal - discount_amount + tax_amount) - total_amount) > 1;
    
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Negative Amounts', COUNT(*) FROM sales
    WHERE total_amount < 0 OR subtotal < 0;
    
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Future Dates', COUNT(*) FROM sales WHERE sale_date > NOW();
    
    INSERT INTO validation_results (check_name, issue_count)
    SELECT 'Negative Stock', COUNT(*) FROM products WHERE stock < 0;
    
    -- Return results
    SELECT * FROM validation_results ORDER BY issue_count DESC;
    
    -- Summary
    SELECT 
        COUNT(*) AS total_checks,
        SUM(CASE WHEN issue_count > 0 THEN 1 ELSE 0 END) AS checks_with_issues,
        SUM(issue_count) AS total_issues
    FROM validation_results;
    
    DROP TEMPORARY TABLE validation_results;
END //
DELIMITER ;

-- ================================================================
-- USAGE
-- ================================================================

-- Run all validations at once
-- CALL sp_run_all_validations();

-- Fix customer totals
-- CALL sp_fix_customer_totals();

-- ================================================================
-- END OF DATA VALIDATION
-- ================================================================
