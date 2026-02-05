-- ================================================================
-- JOIN OPERATIONS
-- All types of JOINs with examples
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: INNER JOIN
-- ================================================================

-- Basic INNER JOIN - returns only matching records
SELECT 
    s.sale_id,
    s.sale_date,
    c.name AS customer_name,
    s.total_amount
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id;

-- Multiple table INNER JOIN
SELECT 
    s.sale_id,
    s.sale_date,
    c.name AS customer_name,
    e.name AS employee_name,
    pm.method_name AS payment_method,
    s.total_amount
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN employees e ON s.employee_id = e.employee_id
INNER JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id;

-- INNER JOIN with aggregation
SELECT 
    c.name AS customer_name,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.total_amount) AS total_spent
FROM customers c
INNER JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- ================================================================
-- SECTION 2: LEFT JOIN (LEFT OUTER JOIN)
-- ================================================================

-- Returns all records from left table, matched records from right
SELECT 
    c.customer_id,
    c.name,
    s.sale_id,
    s.total_amount
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id;

-- Find customers who never made a purchase
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.registration_date
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
WHERE s.sale_id IS NULL;

-- Products never sold
SELECT 
    p.product_id,
    p.name,
    p.price,
    p.stock
FROM products p
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
WHERE sd.sale_detail_id IS NULL;

-- LEFT JOIN with aggregation and NULL handling
SELECT 
    c.customer_id,
    c.name,
    COUNT(s.sale_id) AS order_count,
    COALESCE(SUM(s.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- ================================================================
-- SECTION 3: RIGHT JOIN (RIGHT OUTER JOIN)
-- ================================================================

-- Returns all records from right table, matched from left
SELECT 
    s.sale_id,
    s.sale_date,
    c.name AS customer_name
FROM customers c
RIGHT JOIN sales s ON c.customer_id = s.customer_id;

-- Same result using LEFT JOIN with tables reversed
SELECT 
    s.sale_id,
    s.sale_date,
    c.name AS customer_name
FROM sales s
LEFT JOIN customers c ON s.customer_id = c.customer_id;

-- ================================================================
-- SECTION 4: FULL OUTER JOIN (simulated in MySQL)
-- ================================================================

-- MySQL doesn't have FULL OUTER JOIN, simulate with UNION
SELECT 
    c.customer_id,
    c.name,
    s.sale_id,
    s.total_amount
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id

UNION

SELECT 
    c.customer_id,
    c.name,
    s.sale_id,
    s.total_amount
FROM customers c
RIGHT JOIN sales s ON c.customer_id = s.customer_id;

-- ================================================================
-- SECTION 5: SELF JOIN
-- ================================================================

-- Employee hierarchy (manager relationship)
SELECT 
    e.employee_id,
    e.name AS employee_name,
    e.position,
    m.name AS manager_name,
    m.position AS manager_position
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- Find employees who report to the same manager
SELECT 
    e1.name AS employee1,
    e2.name AS employee2,
    m.name AS shared_manager
FROM employees e1
INNER JOIN employees e2 ON e1.manager_id = e2.manager_id AND e1.employee_id < e2.employee_id
INNER JOIN employees m ON e1.manager_id = m.employee_id;

-- Products in the same category with similar prices
SELECT 
    p1.name AS product1,
    p2.name AS product2,
    p1.price AS price1,
    p2.price AS price2,
    ABS(p1.price - p2.price) AS price_difference
FROM products p1
INNER JOIN products p2 ON p1.category_id = p2.category_id 
    AND p1.product_id < p2.product_id
    AND ABS(p1.price - p2.price) < 10000
ORDER BY price_difference;

-- ================================================================
-- SECTION 6: CROSS JOIN
-- ================================================================

-- Cartesian product (all combinations)
SELECT 
    c.category_name,
    ct.tier_name
FROM categories c
CROSS JOIN customer_tiers ct;

-- Practical use: Generate date range combinations
-- (Useful for reports that need all date-category combinations)
SELECT 
    dates.sale_date,
    categories.category_name
FROM (
    SELECT DISTINCT DATE(sale_date) AS sale_date FROM sales
) dates
CROSS JOIN categories;

-- ================================================================
-- SECTION 7: JOINING ON MULTIPLE CONDITIONS
-- ================================================================

-- Join with multiple ON conditions
SELECT 
    sd.sale_detail_id,
    p.name AS product_name,
    sd.quantity,
    sd.unit_price,
    p.price AS current_price
FROM sales_details sd
INNER JOIN products p ON sd.product_id = p.product_id 
    AND sd.unit_price = p.price;  -- Only where sale price matches current price

-- Join with date range condition
SELECT 
    s.sale_id,
    s.sale_date,
    c.name,
    c.registration_date
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id
    AND s.sale_date >= c.registration_date;  -- Sale must be after registration

-- ================================================================
-- SECTION 8: NON-EQUI JOINS
-- ================================================================

-- Find customers who spent more than tier minimum
SELECT 
    c.name,
    c.total_spent,
    ct.tier_name,
    ct.min_purchases
FROM customers c
INNER JOIN customer_tiers ct ON c.total_spent >= ct.min_purchases
ORDER BY c.name, ct.min_purchases DESC;

-- Get appropriate tier for each customer (highest qualifying tier)
SELECT 
    c.customer_id,
    c.name,
    c.total_spent,
    (SELECT tier_name 
     FROM customer_tiers 
     WHERE c.total_spent >= min_purchases 
     ORDER BY min_purchases DESC 
     LIMIT 1) AS appropriate_tier
FROM customers c;

-- Price range matching
SELECT 
    p.name AS product_name,
    p.price,
    CASE 
        WHEN p.price < 10000 THEN 'Budget'
        WHEN p.price < 50000 THEN 'Mid-Range'
        WHEN p.price < 100000 THEN 'Premium'
        ELSE 'Luxury'
    END AS price_category
FROM products p;

-- ================================================================
-- SECTION 9: THREE OR MORE TABLE JOINS
-- ================================================================

-- Complete sales transaction view
SELECT 
    s.sale_id,
    DATE(s.sale_date) AS sale_date,
    c.name AS customer_name,
    c.city,
    ct.tier_name AS customer_tier,
    e.name AS salesperson,
    pm.method_name AS payment_method,
    p.name AS product_name,
    cat.category_name,
    sd.quantity,
    sd.unit_price,
    sd.line_total,
    s.total_amount AS order_total
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN customer_tiers ct ON c.tier_id = ct.tier_id
LEFT JOIN employees e ON s.employee_id = e.employee_id
LEFT JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id
INNER JOIN sales_details sd ON s.sale_id = sd.sale_id
INNER JOIN products p ON sd.product_id = p.product_id
LEFT JOIN categories cat ON p.category_id = cat.category_id
ORDER BY s.sale_date DESC, s.sale_id, sd.sale_detail_id;

-- ================================================================
-- SECTION 10: USING vs ON
-- ================================================================

-- USING clause (when column names are the same in both tables)
SELECT 
    s.sale_id,
    s.sale_date,
    c.name
FROM sales s
INNER JOIN customers c USING (customer_id);

-- Equivalent with ON
SELECT 
    s.sale_id,
    s.sale_date,
    c.name
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id;

-- ================================================================
-- SECTION 11: NATURAL JOIN (Use with caution)
-- ================================================================

-- NATURAL JOIN automatically joins on all common column names
-- Avoid in production - can lead to unexpected results
SELECT 
    s.sale_id,
    c.name
FROM sales s
NATURAL JOIN customers c;

-- ================================================================
-- SECTION 12: PRACTICAL JOIN EXAMPLES
-- ================================================================

-- Sales summary by category
SELECT 
    cat.category_name,
    COUNT(DISTINCT s.sale_id) AS order_count,
    SUM(sd.quantity) AS units_sold,
    SUM(sd.line_total) AS total_revenue
FROM categories cat
LEFT JOIN products p ON cat.category_id = p.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id AND s.status = 'completed'
GROUP BY cat.category_id, cat.category_name
ORDER BY total_revenue DESC;

-- Top customers by category
SELECT 
    cat.category_name,
    c.name AS customer_name,
    SUM(sd.line_total) AS spent_in_category
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN sales_details sd ON s.sale_id = sd.sale_id
INNER JOIN products p ON sd.product_id = p.product_id
INNER JOIN categories cat ON p.category_id = cat.category_id
WHERE s.status = 'completed'
GROUP BY cat.category_id, cat.category_name, c.customer_id, c.name
ORDER BY cat.category_name, spent_in_category DESC;

-- Employee sales performance with manager comparison
SELECT 
    e.name AS employee_name,
    e.position,
    m.name AS manager_name,
    COUNT(s.sale_id) AS sales_count,
    COALESCE(SUM(s.total_amount), 0) AS total_sales
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
LEFT JOIN sales s ON e.employee_id = s.employee_id AND s.status = 'completed'
GROUP BY e.employee_id, e.name, e.position, m.name
ORDER BY total_sales DESC;

-- ================================================================
-- END OF JOIN OPERATIONS
-- ================================================================
