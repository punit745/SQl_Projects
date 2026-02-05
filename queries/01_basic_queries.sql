-- ================================================================
-- BASIC SQL QUERIES
-- Fundamental SQL operations for beginners
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: SELECT STATEMENTS
-- ================================================================

-- Select all columns from a table
SELECT * FROM customers;

-- Select specific columns
SELECT customer_id, name, email, city FROM customers;

-- Alias column names
SELECT 
    customer_id AS id,
    name AS customer_name,
    email AS email_address,
    total_spent AS lifetime_value
FROM customers;

-- Select with calculations
SELECT 
    name,
    price,
    cost_price,
    price - cost_price AS profit,
    ROUND((price - cost_price) / price * 100, 2) AS profit_margin_pct
FROM products;

-- ================================================================
-- SECTION 2: FILTERING WITH WHERE
-- ================================================================

-- Basic comparison operators
SELECT * FROM products WHERE price > 50000;
SELECT * FROM products WHERE stock <= 10;
SELECT * FROM products WHERE category_id = 2;

-- Multiple conditions with AND/OR
SELECT * FROM customers 
WHERE city = 'Mumbai' AND tier_id >= 2;

SELECT * FROM products 
WHERE price > 10000 OR stock < 5;

-- IN operator
SELECT * FROM customers 
WHERE city IN ('Mumbai', 'Delhi', 'Bangalore');

-- BETWEEN for ranges
SELECT * FROM products 
WHERE price BETWEEN 10000 AND 50000;

SELECT * FROM sales 
WHERE sale_date BETWEEN '2024-01-01' AND '2024-03-31';

-- LIKE for pattern matching
SELECT * FROM customers WHERE name LIKE 'R%';        -- Starts with R
SELECT * FROM customers WHERE email LIKE '%@gmail%'; -- Contains gmail
SELECT * FROM products WHERE name LIKE '%Laptop%';   -- Contains Laptop

-- NULL checks
SELECT * FROM products WHERE cost_price IS NULL;
SELECT * FROM customers WHERE phone IS NOT NULL;

-- NOT operator
SELECT * FROM products WHERE category_id NOT IN (1, 2);
SELECT * FROM customers WHERE city NOT LIKE 'M%';

-- ================================================================
-- SECTION 3: SORTING WITH ORDER BY
-- ================================================================

-- Single column sort
SELECT * FROM products ORDER BY price;           -- Ascending (default)
SELECT * FROM products ORDER BY price DESC;      -- Descending

-- Multiple column sort
SELECT * FROM customers 
ORDER BY city ASC, total_spent DESC;

-- Sort by expression
SELECT 
    name,
    price,
    cost_price,
    price - cost_price AS profit
FROM products
ORDER BY price - cost_price DESC;

-- ================================================================
-- SECTION 4: LIMITING RESULTS
-- ================================================================

-- Get top N rows
SELECT * FROM products ORDER BY price DESC LIMIT 5;

-- Pagination with OFFSET
SELECT * FROM products 
ORDER BY product_id 
LIMIT 10 OFFSET 20;  -- Skip first 20, get next 10

-- Get nth highest price
SELECT * FROM products 
ORDER BY price DESC 
LIMIT 1 OFFSET 2;  -- 3rd highest

-- ================================================================
-- SECTION 5: AGGREGATE FUNCTIONS
-- ================================================================

-- COUNT
SELECT COUNT(*) AS total_customers FROM customers;
SELECT COUNT(DISTINCT city) AS unique_cities FROM customers;
SELECT COUNT(phone) AS customers_with_phone FROM customers;

-- SUM
SELECT SUM(total_amount) AS total_revenue FROM sales;
SELECT SUM(stock) AS total_inventory FROM products;

-- AVG
SELECT AVG(price) AS average_price FROM products;
SELECT ROUND(AVG(total_amount), 2) AS avg_order_value FROM sales;

-- MIN and MAX
SELECT 
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM products;

SELECT 
    MIN(sale_date) AS first_sale,
    MAX(sale_date) AS last_sale
FROM sales;

-- Multiple aggregates
SELECT 
    COUNT(*) AS total_products,
    SUM(stock) AS total_units,
    AVG(price) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM products;

-- ================================================================
-- SECTION 6: GROUP BY
-- ================================================================

-- Simple grouping
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC;

-- Group with multiple aggregates
SELECT 
    category_id,
    COUNT(*) AS product_count,
    AVG(price) AS avg_price,
    SUM(stock) AS total_stock
FROM products
GROUP BY category_id;

-- Grouping by multiple columns
SELECT 
    city,
    tier_id,
    COUNT(*) AS customer_count
FROM customers
GROUP BY city, tier_id
ORDER BY city, tier_id;

-- Group by date parts
SELECT 
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    COUNT(*) AS order_count,
    SUM(total_amount) AS revenue
FROM sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY year, month;

-- ================================================================
-- SECTION 7: HAVING CLAUSE
-- ================================================================

-- Filter groups (vs WHERE which filters rows)
SELECT city, COUNT(*) AS customer_count
FROM customers
GROUP BY city
HAVING COUNT(*) >= 2;

-- Combined WHERE and HAVING
SELECT 
    category_id,
    AVG(price) AS avg_price,
    COUNT(*) AS product_count
FROM products
WHERE stock > 0
GROUP BY category_id
HAVING AVG(price) > 20000;

-- ================================================================
-- SECTION 8: STRING FUNCTIONS
-- ================================================================

SELECT 
    name,
    UPPER(name) AS upper_name,
    LOWER(email) AS lower_email,
    LENGTH(name) AS name_length,
    SUBSTRING(name, 1, 3) AS first_3_chars,
    CONCAT(name, ' - ', city) AS customer_location,
    LEFT(name, 1) AS first_initial,
    RIGHT(phone, 4) AS last_4_digits,
    TRIM(name) AS trimmed_name,
    REPLACE(email, '@', ' [at] ') AS masked_email
FROM customers;

-- ================================================================
-- SECTION 9: DATE FUNCTIONS
-- ================================================================

SELECT 
    sale_date,
    DATE(sale_date) AS date_only,
    TIME(sale_date) AS time_only,
    YEAR(sale_date) AS year,
    MONTH(sale_date) AS month,
    DAY(sale_date) AS day,
    DAYNAME(sale_date) AS day_name,
    MONTHNAME(sale_date) AS month_name,
    QUARTER(sale_date) AS quarter,
    WEEK(sale_date) AS week_number,
    HOUR(sale_date) AS hour,
    MINUTE(sale_date) AS minute
FROM sales;

-- Date calculations
SELECT 
    sale_date,
    DATE_ADD(sale_date, INTERVAL 7 DAY) AS plus_7_days,
    DATE_SUB(sale_date, INTERVAL 1 MONTH) AS minus_1_month,
    DATEDIFF(CURRENT_DATE, sale_date) AS days_ago,
    TIMESTAMPDIFF(HOUR, sale_date, NOW()) AS hours_ago
FROM sales;

-- Formatting dates
SELECT 
    sale_date,
    DATE_FORMAT(sale_date, '%Y-%m-%d') AS formatted_date,
    DATE_FORMAT(sale_date, '%d/%m/%Y') AS indian_format,
    DATE_FORMAT(sale_date, '%W, %M %d, %Y') AS full_date,
    DATE_FORMAT(sale_date, '%h:%i %p') AS time_12hr
FROM sales;

-- ================================================================
-- SECTION 10: NUMERIC FUNCTIONS
-- ================================================================

SELECT 
    price,
    ROUND(price, 0) AS rounded,
    CEIL(price) AS ceiling,
    FLOOR(price) AS floor_val,
    ABS(-price) AS absolute,
    MOD(price, 1000) AS modulo,
    POWER(2, 10) AS power_of_2,
    SQRT(price) AS square_root,
    FORMAT(price, 2) AS formatted
FROM products;

-- ================================================================
-- SECTION 11: CASE STATEMENTS
-- ================================================================

-- Simple CASE
SELECT 
    name,
    price,
    CASE 
        WHEN price < 10000 THEN 'Budget'
        WHEN price < 50000 THEN 'Mid-Range'
        WHEN price < 100000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_segment
FROM products;

-- CASE with aggregation
SELECT 
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
    SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN status = 'refunded' THEN 1 ELSE 0 END) AS refunded_orders
FROM sales;

-- ================================================================
-- SECTION 12: DISTINCT AND UNIQUE VALUES
-- ================================================================

-- Get unique values
SELECT DISTINCT city FROM customers;
SELECT DISTINCT category_id FROM products;
SELECT DISTINCT YEAR(sale_date) AS years FROM sales;

-- Count distinct
SELECT COUNT(DISTINCT customer_id) AS unique_buyers FROM sales;

-- ================================================================
-- END OF BASIC QUERIES
-- ================================================================
