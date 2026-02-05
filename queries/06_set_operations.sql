-- ================================================================
-- SET OPERATIONS AND ADVANCED SQL
-- UNION, INTERSECT, EXCEPT, and other advanced operations
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: UNION
-- ================================================================

-- UNION - combines results, removes duplicates
SELECT city FROM customers
UNION
SELECT city FROM (SELECT 'Mumbai' AS city UNION SELECT 'Delhi' UNION SELECT 'Bangalore') t;

-- UNION ALL - combines results, keeps duplicates
SELECT 'Customer' AS entity_type, name, email FROM customers
UNION ALL
SELECT 'Employee' AS entity_type, name, email FROM employees;

-- UNION with different queries
SELECT 
    'Low Stock' AS alert_type,
    name AS item_name,
    CONCAT(stock, ' units') AS details
FROM products
WHERE stock <= reorder_level

UNION

SELECT 
    'Inactive Customer' AS alert_type,
    name AS item_name,
    CONCAT(DATEDIFF(CURRENT_DATE, last_purchase_date), ' days since last purchase') AS details
FROM customers
WHERE DATEDIFF(CURRENT_DATE, last_purchase_date) > 90;

-- ================================================================
-- SECTION 2: INTERSECT (Simulated in MySQL)
-- ================================================================

-- MySQL doesn't have INTERSECT, simulate with INNER JOIN
-- Find cities that have both customers and employees
SELECT DISTINCT c.city
FROM customers c
INNER JOIN (SELECT DISTINCT city FROM employees WHERE city IS NOT NULL) e ON c.city = e.city;

-- Alternative using EXISTS
SELECT DISTINCT city
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.city = c.city
);

-- Alternative using IN
SELECT DISTINCT city
FROM customers
WHERE city IN (SELECT city FROM employees WHERE city IS NOT NULL);

-- ================================================================
-- SECTION 3: EXCEPT (Simulated in MySQL)
-- ================================================================

-- MySQL doesn't have EXCEPT, simulate with LEFT JOIN + NULL check
-- Find customers who are not in a specific list
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN (SELECT 1 AS id UNION SELECT 2 UNION SELECT 3) exclude ON c.customer_id = exclude.id
WHERE exclude.id IS NULL;

-- Alternative using NOT EXISTS
SELECT customer_id, name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM sales s WHERE s.customer_id = c.customer_id
);

-- Alternative using NOT IN
SELECT customer_id, name
FROM customers
WHERE customer_id NOT IN (SELECT DISTINCT customer_id FROM sales);

-- ================================================================
-- SECTION 4: PIVOT (Simulated in MySQL)
-- ================================================================

-- Monthly sales pivot
SELECT 
    YEAR(sale_date) AS year,
    SUM(CASE WHEN MONTH(sale_date) = 1 THEN total_amount ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(sale_date) = 2 THEN total_amount ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(sale_date) = 3 THEN total_amount ELSE 0 END) AS Mar,
    SUM(CASE WHEN MONTH(sale_date) = 4 THEN total_amount ELSE 0 END) AS Apr,
    SUM(CASE WHEN MONTH(sale_date) = 5 THEN total_amount ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(sale_date) = 6 THEN total_amount ELSE 0 END) AS Jun,
    SUM(CASE WHEN MONTH(sale_date) = 7 THEN total_amount ELSE 0 END) AS Jul,
    SUM(CASE WHEN MONTH(sale_date) = 8 THEN total_amount ELSE 0 END) AS Aug,
    SUM(CASE WHEN MONTH(sale_date) = 9 THEN total_amount ELSE 0 END) AS Sep,
    SUM(CASE WHEN MONTH(sale_date) = 10 THEN total_amount ELSE 0 END) AS Oct,
    SUM(CASE WHEN MONTH(sale_date) = 11 THEN total_amount ELSE 0 END) AS Nov,
    SUM(CASE WHEN MONTH(sale_date) = 12 THEN total_amount ELSE 0 END) AS `Dec`
FROM sales
WHERE status = 'completed'
GROUP BY YEAR(sale_date)
ORDER BY year;

-- Category sales by customer tier (pivot)
SELECT 
    cat.category_name,
    SUM(CASE WHEN ct.tier_name = 'Bronze' THEN sd.line_total ELSE 0 END) AS Bronze_Sales,
    SUM(CASE WHEN ct.tier_name = 'Silver' THEN sd.line_total ELSE 0 END) AS Silver_Sales,
    SUM(CASE WHEN ct.tier_name = 'Gold' THEN sd.line_total ELSE 0 END) AS Gold_Sales,
    SUM(CASE WHEN ct.tier_name = 'Platinum' THEN sd.line_total ELSE 0 END) AS Platinum_Sales
FROM categories cat
LEFT JOIN products p ON cat.category_id = p.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id AND s.status = 'completed'
LEFT JOIN customers c ON s.customer_id = c.customer_id
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
GROUP BY cat.category_id, cat.category_name
ORDER BY cat.category_name;

-- ================================================================
-- SECTION 5: UNPIVOT (Simulated in MySQL)
-- ================================================================

-- Convert columns to rows
SELECT 
    customer_id,
    'name' AS attribute,
    name AS value
FROM customers
UNION ALL
SELECT 
    customer_id,
    'email' AS attribute,
    email AS value
FROM customers
UNION ALL
SELECT 
    customer_id,
    'city' AS attribute,
    city AS value
FROM customers
ORDER BY customer_id, attribute;

-- ================================================================
-- SECTION 6: GROUPING SETS (Simulated in MySQL)
-- ================================================================

-- MySQL doesn't have GROUPING SETS, simulate with UNION ALL
-- Sales by category, by month, and total
SELECT 
    cat.category_name,
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    SUM(sd.line_total) AS revenue
FROM sales s
JOIN sales_details sd ON s.sale_id = sd.sale_id
JOIN products p ON sd.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE s.status = 'completed'
GROUP BY cat.category_id, cat.category_name, DATE_FORMAT(s.sale_date, '%Y-%m')

UNION ALL

SELECT 
    cat.category_name,
    'ALL MONTHS' AS month,
    SUM(sd.line_total) AS revenue
FROM sales s
JOIN sales_details sd ON s.sale_id = sd.sale_id
JOIN products p ON sd.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE s.status = 'completed'
GROUP BY cat.category_id, cat.category_name

UNION ALL

SELECT 
    'ALL CATEGORIES' AS category_name,
    DATE_FORMAT(s.sale_date, '%Y-%m') AS month,
    SUM(sd.line_total) AS revenue
FROM sales s
JOIN sales_details sd ON s.sale_id = sd.sale_id
WHERE s.status = 'completed'
GROUP BY DATE_FORMAT(s.sale_date, '%Y-%m')

ORDER BY category_name, month;

-- GROUP BY with ROLLUP (MySQL supports this)
SELECT 
    COALESCE(cat.category_name, 'TOTAL') AS category,
    COALESCE(DATE_FORMAT(s.sale_date, '%Y-%m'), 'ALL MONTHS') AS month,
    SUM(sd.line_total) AS revenue
FROM sales s
JOIN sales_details sd ON s.sale_id = sd.sale_id
JOIN products p ON sd.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE s.status = 'completed'
GROUP BY cat.category_name, DATE_FORMAT(s.sale_date, '%Y-%m') WITH ROLLUP;

-- ================================================================
-- SECTION 7: INSERT/UPDATE/DELETE with SELECTs
-- ================================================================

-- INSERT from SELECT
-- CREATE TABLE customer_backup AS SELECT * FROM customers;

-- INSERT specific columns from SELECT
-- INSERT INTO customer_backup (customer_id, name, email)
-- SELECT customer_id, name, email FROM customers WHERE tier_id = 4;

-- UPDATE with subquery
UPDATE products p
SET p.stock = p.stock + 10
WHERE p.product_id IN (
    SELECT product_id FROM (
        SELECT product_id FROM products WHERE stock < reorder_level
    ) AS low_stock
);

-- UPDATE with JOIN
UPDATE customers c
JOIN (
    SELECT customer_id, SUM(total_amount) AS actual_total
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
) s ON c.customer_id = s.customer_id
SET c.total_spent = s.actual_total;

-- DELETE with subquery
-- DELETE FROM customers 
-- WHERE customer_id NOT IN (
--     SELECT DISTINCT customer_id FROM sales
-- );

-- ================================================================
-- SECTION 8: TEMPORARY TABLES
-- ================================================================

-- Create temporary table
CREATE TEMPORARY TABLE IF NOT EXISTS temp_high_value_customers AS
SELECT customer_id, name, total_spent
FROM customers
WHERE total_spent > 50000;

-- Use temporary table
SELECT * FROM temp_high_value_customers;

-- Join with temporary table
SELECT 
    thvc.name,
    thvc.total_spent,
    COUNT(s.sale_id) AS order_count
FROM temp_high_value_customers thvc
LEFT JOIN sales s ON thvc.customer_id = s.customer_id
GROUP BY thvc.customer_id, thvc.name, thvc.total_spent;

-- Drop temporary table
DROP TEMPORARY TABLE IF EXISTS temp_high_value_customers;

-- ================================================================
-- SECTION 9: UPSERT (INSERT ON DUPLICATE KEY UPDATE)
-- ================================================================

-- Example UPSERT pattern
-- INSERT INTO products (product_id, name, price, stock)
-- VALUES (1, 'Updated Product', 25000, 50)
-- ON DUPLICATE KEY UPDATE 
--     name = VALUES(name),
--     price = VALUES(price),
--     stock = stock + VALUES(stock);

-- REPLACE INTO (deletes and re-inserts)
-- REPLACE INTO products (product_id, name, price, stock)
-- VALUES (1, 'Replaced Product', 25000, 50);

-- ================================================================
-- SECTION 10: CONDITIONAL EXPRESSIONS
-- ================================================================

-- COALESCE - return first non-null
SELECT 
    customer_id,
    COALESCE(phone, email, 'No Contact') AS primary_contact
FROM customers;

-- NULLIF - return NULL if equal
SELECT 
    name,
    price,
    cost_price,
    price - cost_price AS profit,
    -- Avoid division by zero
    price / NULLIF(cost_price, 0) AS markup_ratio
FROM products;

-- IFNULL - MySQL specific
SELECT 
    customer_id,
    name,
    IFNULL(phone, 'N/A') AS phone
FROM customers;

-- IF function
SELECT 
    name,
    stock,
    IF(stock > reorder_level, 'In Stock', 'Low Stock') AS stock_status
FROM products;

-- ================================================================
-- SECTION 11: INFORMATION SCHEMA QUERIES
-- ================================================================

-- List all tables
SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
ORDER BY TABLE_NAME;

-- List all columns for a table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
  AND TABLE_NAME = 'customers'
ORDER BY ORDINAL_POSITION;

-- List all indexes
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- List all foreign keys
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- ================================================================
-- END OF SET OPERATIONS
-- ================================================================
