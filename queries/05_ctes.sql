-- ================================================================
-- COMMON TABLE EXPRESSIONS (CTEs)
-- Standard and recursive CTEs
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: BASIC CTEs
-- ================================================================

-- Simple CTE
WITH high_value_customers AS (
    SELECT customer_id, name, total_spent
    FROM customers
    WHERE total_spent >= 50000
)
SELECT * FROM high_value_customers
ORDER BY total_spent DESC;

-- CTE with aggregation
WITH customer_order_stats AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent,
        AVG(total_amount) AS avg_order_value
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    c.name,
    c.email,
    cos.order_count,
    cos.total_spent,
    cos.avg_order_value
FROM customers c
JOIN customer_order_stats cos ON c.customer_id = cos.customer_id
ORDER BY cos.total_spent DESC;

-- ================================================================
-- SECTION 2: MULTIPLE CTEs
-- ================================================================

-- Chain multiple CTEs
WITH 
customer_sales AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spent
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
),
customer_ranks AS (
    SELECT 
        customer_id,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM customer_sales
)
SELECT 
    c.name,
    cr.total_spent,
    cr.spending_rank
FROM customers c
JOIN customer_ranks cr ON c.customer_id = cr.customer_id
WHERE cr.spending_rank <= 10;

-- CTEs referencing previous CTEs
WITH 
monthly_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        SUM(total_amount) AS revenue
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
monthly_growth AS (
    SELECT 
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
        revenue - LAG(revenue) OVER (ORDER BY month) AS absolute_growth
    FROM monthly_sales
),
growth_analysis AS (
    SELECT 
        month,
        revenue,
        prev_revenue,
        absolute_growth,
        CASE 
            WHEN prev_revenue > 0 THEN ROUND(absolute_growth / prev_revenue * 100, 2)
            ELSE NULL
        END AS pct_growth
    FROM monthly_growth
)
SELECT * FROM growth_analysis
WHERE pct_growth IS NOT NULL
ORDER BY month;

-- ================================================================
-- SECTION 3: CTEs WITH JOINS
-- ================================================================

-- Complex reporting with CTEs
WITH 
product_sales AS (
    SELECT 
        sd.product_id,
        SUM(sd.quantity) AS units_sold,
        SUM(sd.line_total) AS revenue
    FROM sales_details sd
    JOIN sales s ON sd.sale_id = s.sale_id
    WHERE s.status = 'completed'
    GROUP BY sd.product_id
),
category_totals AS (
    SELECT 
        p.category_id,
        SUM(ps.revenue) AS category_revenue
    FROM products p
    LEFT JOIN product_sales ps ON p.product_id = ps.product_id
    GROUP BY p.category_id
)
SELECT 
    cat.category_name,
    p.name AS product_name,
    COALESCE(ps.units_sold, 0) AS units_sold,
    COALESCE(ps.revenue, 0) AS product_revenue,
    ct.category_revenue,
    CASE 
        WHEN ct.category_revenue > 0 
        THEN ROUND(COALESCE(ps.revenue, 0) / ct.category_revenue * 100, 2)
        ELSE 0
    END AS pct_of_category
FROM categories cat
LEFT JOIN products p ON cat.category_id = p.category_id
LEFT JOIN product_sales ps ON p.product_id = ps.product_id
LEFT JOIN category_totals ct ON cat.category_id = ct.category_id
ORDER BY cat.category_name, product_revenue DESC;

-- ================================================================
-- SECTION 4: RECURSIVE CTEs
-- ================================================================

-- Employee hierarchy
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level managers (no manager)
    SELECT 
        employee_id,
        name,
        position,
        manager_id,
        1 AS level,
        CAST(name AS CHAR(500)) AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees with managers
    SELECT 
        e.employee_id,
        e.name,
        e.position,
        e.manager_id,
        eh.level + 1,
        CONCAT(eh.path, ' > ', e.name)
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    CONCAT(REPEAT('  ', level - 1), name) AS indented_name,
    position,
    level,
    path
FROM employee_hierarchy
ORDER BY path;

-- Generate date series
WITH RECURSIVE date_series AS (
    SELECT DATE('2024-01-01') AS dt
    UNION ALL
    SELECT DATE_ADD(dt, INTERVAL 1 DAY)
    FROM date_series
    WHERE dt < '2024-01-31'
)
SELECT dt AS date_value FROM date_series;

-- Number sequence
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 10
)
SELECT n FROM numbers;

-- Category hierarchy (if categories had parent-child relationship)
WITH RECURSIVE category_tree AS (
    -- Root categories
    SELECT 
        category_id,
        category_name,
        CAST(NULL AS SIGNED) AS parent_category_id,
        1 AS depth,
        CAST(category_name AS CHAR(500)) AS full_path
    FROM categories
    WHERE category_id IN (1, 2, 3)  -- Mock parent check
    
    UNION ALL
    
    -- Subcategories (simulated)
    SELECT 
        c.category_id + 100,  -- Mock child ID
        CONCAT('Sub-', c.category_name),
        c.category_id,
        ct.depth + 1,
        CONCAT(ct.full_path, ' > ', 'Sub-', c.category_name)
    FROM categories c
    INNER JOIN category_tree ct ON c.category_id = ct.category_id
    WHERE ct.depth < 2  -- Limit depth
)
SELECT * FROM category_tree
ORDER BY full_path;

-- Running total calculation with recursive CTE
WITH RECURSIVE running_balance AS (
    SELECT 
        sale_id,
        sale_date,
        total_amount,
        total_amount AS balance,
        1 AS row_num
    FROM (
        SELECT sale_id, sale_date, total_amount,
               ROW_NUMBER() OVER (ORDER BY sale_date, sale_id) AS rn
        FROM sales WHERE status = 'completed'
    ) t
    WHERE rn = 1
    
    UNION ALL
    
    SELECT 
        s.sale_id,
        s.sale_date,
        s.total_amount,
        rb.balance + s.total_amount,
        rb.row_num + 1
    FROM running_balance rb
    JOIN (
        SELECT sale_id, sale_date, total_amount,
               ROW_NUMBER() OVER (ORDER BY sale_date, sale_id) AS rn
        FROM sales WHERE status = 'completed'
    ) s ON s.rn = rb.row_num + 1
)
SELECT * FROM running_balance
ORDER BY row_num;

-- ================================================================
-- SECTION 5: PRACTICAL CTE EXAMPLES
-- ================================================================

-- Customer RFM Analysis
WITH 
last_order_dates AS (
    SELECT 
        customer_id,
        MAX(sale_date) AS last_order_date,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT 
        customer_id,
        last_order_date,
        order_count,
        total_spent,
        NTILE(5) OVER (ORDER BY DATEDIFF(CURRENT_DATE, last_order_date)) AS recency_score,
        NTILE(5) OVER (ORDER BY order_count) AS frequency_score,
        NTILE(5) OVER (ORDER BY total_spent) AS monetary_score
    FROM last_order_dates
),
rfm_segments AS (
    SELECT 
        *,
        CONCAT(recency_score, frequency_score, monetary_score) AS rfm_cell,
        recency_score + frequency_score + monetary_score AS rfm_total_score
    FROM rfm_scores
)
SELECT 
    c.name,
    c.email,
    rs.last_order_date,
    rs.order_count,
    rs.total_spent,
    rs.rfm_cell,
    rs.rfm_total_score,
    CASE 
        WHEN rs.rfm_total_score >= 13 THEN 'Champions'
        WHEN rs.rfm_total_score >= 10 THEN 'Loyal Customers'
        WHEN rs.rfm_total_score >= 7 THEN 'Potential Loyalists'
        WHEN rs.rfm_total_score >= 4 THEN 'At Risk'
        ELSE 'Lost'
    END AS customer_segment
FROM customers c
JOIN rfm_segments rs ON c.customer_id = rs.customer_id
ORDER BY rs.rfm_total_score DESC;

-- Cohort Analysis
WITH 
first_purchase AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(sale_date), '%Y-%m') AS cohort_month
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
),
purchase_months AS (
    SELECT 
        s.customer_id,
        fp.cohort_month,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS purchase_month,
        PERIOD_DIFF(
            DATE_FORMAT(s.sale_date, '%Y%m'),
            DATE_FORMAT(STR_TO_DATE(CONCAT(fp.cohort_month, '-01'), '%Y-%m-%d'), '%Y%m')
        ) AS months_since_first
    FROM sales s
    JOIN first_purchase fp ON s.customer_id = fp.customer_id
    WHERE s.status = 'completed'
),
cohort_data AS (
    SELECT 
        cohort_month,
        months_since_first,
        COUNT(DISTINCT customer_id) AS customers
    FROM purchase_months
    GROUP BY cohort_month, months_since_first
)
SELECT 
    cohort_month,
    MAX(CASE WHEN months_since_first = 0 THEN customers END) AS month_0,
    MAX(CASE WHEN months_since_first = 1 THEN customers END) AS month_1,
    MAX(CASE WHEN months_since_first = 2 THEN customers END) AS month_2,
    MAX(CASE WHEN months_since_first = 3 THEN customers END) AS month_3
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;

-- Year-over-Year comparison
WITH 
yearly_monthly_sales AS (
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(total_amount) AS revenue
    FROM sales
    WHERE status = 'completed'
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT 
    curr.month,
    curr.year AS current_year,
    curr.revenue AS current_revenue,
    prev.revenue AS prev_year_revenue,
    curr.revenue - COALESCE(prev.revenue, 0) AS yoy_change,
    CASE 
        WHEN prev.revenue > 0 
        THEN ROUND((curr.revenue - prev.revenue) / prev.revenue * 100, 2)
        ELSE NULL
    END AS yoy_growth_pct
FROM yearly_monthly_sales curr
LEFT JOIN yearly_monthly_sales prev ON curr.month = prev.month 
    AND curr.year = prev.year + 1
ORDER BY curr.year, curr.month;

-- ================================================================
-- END OF CTEs
-- ================================================================
