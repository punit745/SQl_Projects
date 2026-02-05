-- ================================================================
-- SUBQUERIES AND DERIVED TABLES
-- Scalar, row, table, and correlated subqueries
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: SCALAR SUBQUERIES (Return single value)
-- ================================================================

-- Compare to average
SELECT 
    name,
    price,
    (SELECT AVG(price) FROM products) AS avg_price,
    price - (SELECT AVG(price) FROM products) AS diff_from_avg
FROM products
ORDER BY diff_from_avg DESC;

-- Get customer's total compared to average customer
SELECT 
    name,
    total_spent,
    (SELECT AVG(total_spent) FROM customers WHERE total_spent > 0) AS avg_spent,
    total_spent / (SELECT AVG(total_spent) FROM customers WHERE total_spent > 0) * 100 AS pct_of_avg
FROM customers
WHERE total_spent > 0
ORDER BY total_spent DESC;

-- Count in subquery
SELECT 
    c.name,
    c.city,
    (SELECT COUNT(*) FROM customers WHERE city = c.city) AS customers_in_same_city
FROM customers c;

-- ================================================================
-- SECTION 2: ROW SUBQUERIES (Return single row)
-- ================================================================

-- Find customer with maximum spending
SELECT * FROM customers
WHERE total_spent = (SELECT MAX(total_spent) FROM customers);

-- Find the most expensive product in each category (simplified)
SELECT * FROM products
WHERE (category_id, price) IN (
    SELECT category_id, MAX(price)
    FROM products
    GROUP BY category_id
);

-- Find the latest sale
SELECT * FROM sales
WHERE sale_date = (SELECT MAX(sale_date) FROM sales);

-- ================================================================
-- SECTION 3: TABLE SUBQUERIES (Return multiple rows/columns)
-- ================================================================

-- Using IN with subquery
SELECT * FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM sales
    WHERE total_amount > 50000
);

-- Using NOT IN
SELECT * FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM sales_details
);

-- Using EXISTS
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM sales s
    WHERE s.customer_id = c.customer_id
    AND s.total_amount > 100000
);

-- Using NOT EXISTS
SELECT * FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM sales s
    WHERE s.customer_id = c.customer_id
);

-- ================================================================
-- SECTION 4: CORRELATED SUBQUERIES
-- ================================================================

-- Find products priced above their category average
SELECT 
    p.name,
    p.category_id,
    p.price,
    (SELECT AVG(p2.price) FROM products p2 WHERE p2.category_id = p.category_id) AS category_avg
FROM products p
WHERE p.price > (
    SELECT AVG(p2.price) 
    FROM products p2 
    WHERE p2.category_id = p.category_id
);

-- Find customers whose spending exceeds their city's average
SELECT 
    c.name,
    c.city,
    c.total_spent,
    (SELECT AVG(c2.total_spent) FROM customers c2 WHERE c2.city = c.city) AS city_avg
FROM customers c
WHERE c.total_spent > (
    SELECT AVG(c2.total_spent)
    FROM customers c2
    WHERE c2.city = c.city
);

-- Find the nth highest value using correlated subquery
-- 3rd highest priced product
SELECT * FROM products p1
WHERE 2 = (
    SELECT COUNT(DISTINCT p2.price)
    FROM products p2
    WHERE p2.price > p1.price
);

-- Running total using correlated subquery (less efficient than window functions)
SELECT 
    sale_id,
    sale_date,
    total_amount,
    (SELECT SUM(s2.total_amount) 
     FROM sales s2 
     WHERE s2.sale_id <= s.sale_id) AS running_total
FROM sales s
ORDER BY sale_id;

-- ================================================================
-- SECTION 5: DERIVED TABLES (Subqueries in FROM clause)
-- ================================================================

-- Use derived table for aggregations
SELECT 
    city_stats.city,
    city_stats.customer_count,
    city_stats.total_revenue
FROM (
    SELECT 
        city,
        COUNT(*) AS customer_count,
        SUM(total_spent) AS total_revenue
    FROM customers
    GROUP BY city
) AS city_stats
WHERE city_stats.customer_count >= 1
ORDER BY city_stats.total_revenue DESC;

-- Join with derived table
SELECT 
    c.name,
    c.total_spent,
    tier_summary.tier_avg
FROM customers c
JOIN (
    SELECT tier_id, AVG(total_spent) AS tier_avg
    FROM customers
    GROUP BY tier_id
) AS tier_summary ON c.tier_id = tier_summary.tier_id
WHERE c.total_spent > tier_summary.tier_avg;

-- Multiple derived tables
SELECT 
    monthly.month,
    monthly.monthly_revenue,
    yearly.yearly_revenue,
    monthly.monthly_revenue / yearly.yearly_revenue * 100 AS pct_of_year
FROM (
    SELECT 
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        SUM(total_amount) AS monthly_revenue
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
) AS monthly
CROSS JOIN (
    SELECT SUM(total_amount) AS yearly_revenue
    FROM sales
    WHERE status = 'completed'
) AS yearly
ORDER BY month;

-- ================================================================
-- SECTION 6: SUBQUERIES IN SELECT CLAUSE
-- ================================================================

-- Multiple scalar subqueries
SELECT 
    c.customer_id,
    c.name,
    (SELECT COUNT(*) FROM sales s WHERE s.customer_id = c.customer_id) AS order_count,
    (SELECT SUM(total_amount) FROM sales s WHERE s.customer_id = c.customer_id) AS total_spent,
    (SELECT MAX(sale_date) FROM sales s WHERE s.customer_id = c.customer_id) AS last_order_date
FROM customers c;

-- Subquery with CASE
SELECT 
    p.name,
    p.price,
    CASE 
        WHEN p.price > (SELECT AVG(price) FROM products) THEN 'Above Average'
        WHEN p.price < (SELECT AVG(price) FROM products) THEN 'Below Average'
        ELSE 'Average'
    END AS price_comparison
FROM products p;

-- ================================================================
-- SECTION 7: SUBQUERIES IN WHERE CLAUSE
-- ================================================================

-- ANY (SOME)
SELECT * FROM products
WHERE price > ANY (
    SELECT AVG(price) FROM products GROUP BY category_id
);

-- ALL
SELECT * FROM products
WHERE price > ALL (
    SELECT AVG(price) FROM products GROUP BY category_id
);

-- Comparison with subquery
SELECT * FROM customers
WHERE total_spent >= (
    SELECT AVG(total_spent) * 2 FROM customers
);

-- ================================================================
-- SECTION 8: SUBQUERIES IN HAVING CLAUSE
-- ================================================================

-- Categories with above-average product count
SELECT 
    category_id,
    COUNT(*) AS product_count
FROM products
GROUP BY category_id
HAVING COUNT(*) > (
    SELECT AVG(product_cnt) 
    FROM (
        SELECT COUNT(*) AS product_cnt 
        FROM products 
        GROUP BY category_id
    ) AS counts
);

-- ================================================================
-- SECTION 9: NESTED SUBQUERIES
-- ================================================================

-- Multiple levels of nesting
SELECT * FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM sales
    WHERE sale_id IN (
        SELECT sale_id FROM sales_details
        WHERE product_id IN (
            SELECT product_id FROM products
            WHERE category_id = 1
        )
    )
);

-- ================================================================
-- SECTION 10: PRACTICAL EXAMPLES
-- ================================================================

-- Top N per group (customers with highest spending per city)
SELECT *
FROM customers c1
WHERE (
    SELECT COUNT(DISTINCT c2.total_spent)
    FROM customers c2
    WHERE c2.city = c1.city AND c2.total_spent >= c1.total_spent
) <= 3
ORDER BY city, total_spent DESC;

-- Find consecutive transactions
SELECT 
    s1.sale_id,
    s1.customer_id,
    s1.sale_date,
    s1.total_amount AS current_amount,
    (SELECT s2.total_amount 
     FROM sales s2 
     WHERE s2.customer_id = s1.customer_id 
       AND s2.sale_date < s1.sale_date
     ORDER BY s2.sale_date DESC 
     LIMIT 1) AS previous_amount
FROM sales s1
ORDER BY s1.customer_id, s1.sale_date;

-- Products that are more expensive than the average of their category
-- and have been sold more than the average times
SELECT 
    p.product_id,
    p.name,
    p.price,
    p.category_id
FROM products p
WHERE p.price > (
    SELECT AVG(p2.price) FROM products p2 WHERE p2.category_id = p.category_id
)
AND (
    SELECT COUNT(*) FROM sales_details sd WHERE sd.product_id = p.product_id
) > (
    SELECT AVG(sale_count) FROM (
        SELECT product_id, COUNT(*) AS sale_count
        FROM sales_details
        GROUP BY product_id
    ) AS product_sales
);

-- ================================================================
-- END OF SUBQUERIES
-- ================================================================
