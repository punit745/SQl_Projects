-- ================================================================
-- WINDOW FUNCTIONS
-- ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, etc.
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: RANKING FUNCTIONS
-- ================================================================

-- ROW_NUMBER - assigns unique sequential numbers
SELECT 
    customer_id,
    name,
    total_spent,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS row_num
FROM customers;

-- RANK - same rank for ties, gaps after ties
SELECT 
    product_id,
    name,
    price,
    RANK() OVER (ORDER BY price DESC) AS price_rank
FROM products;

-- DENSE_RANK - same rank for ties, no gaps
SELECT 
    product_id,
    name,
    price,
    RANK() OVER (ORDER BY price DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank_val
FROM products;

-- Compare all three ranking functions
SELECT 
    product_id,
    name,
    price,
    ROW_NUMBER() OVER (ORDER BY price DESC) AS row_num,
    RANK() OVER (ORDER BY price DESC) AS rank_val,
    DENSE_RANK() OVER (ORDER BY price DESC) AS dense_rank_val
FROM products;

-- Ranking within groups (partitions)
SELECT 
    category_id,
    product_id,
    name,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rank_in_category
FROM products;

-- Get top N per category
SELECT *
FROM (
    SELECT 
        category_id,
        product_id,
        name,
        price,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS rn
    FROM products
) ranked
WHERE rn <= 3;

-- ================================================================
-- SECTION 2: NTILE - Dividing into buckets
-- ================================================================

-- Divide customers into 4 quartiles by spending
SELECT 
    customer_id,
    name,
    total_spent,
    NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_quartile
FROM customers;

-- Assign percentile ranks
SELECT 
    customer_id,
    name,
    total_spent,
    NTILE(100) OVER (ORDER BY total_spent DESC) AS percentile
FROM customers;

-- Divide products into price tiers
SELECT 
    product_id,
    name,
    price,
    CASE NTILE(3) OVER (ORDER BY price)
        WHEN 1 THEN 'Budget'
        WHEN 2 THEN 'Mid-Range'
        WHEN 3 THEN 'Premium'
    END AS price_tier
FROM products;

-- ================================================================
-- SECTION 3: AGGREGATE WINDOW FUNCTIONS
-- ================================================================

-- Running totals
SELECT 
    sale_id,
    sale_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY sale_date, sale_id) AS running_total
FROM sales
WHERE status = 'completed';

-- Running total per customer
SELECT 
    customer_id,
    sale_id,
    sale_date,
    total_amount,
    SUM(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date, sale_id
    ) AS customer_running_total
FROM sales
WHERE status = 'completed';

-- Running average
SELECT 
    sale_id,
    sale_date,
    total_amount,
    ROUND(AVG(total_amount) OVER (ORDER BY sale_date, sale_id), 2) AS running_avg
FROM sales
WHERE status = 'completed';

-- Moving average (last 3 orders)
SELECT 
    sale_id,
    sale_date,
    total_amount,
    ROUND(AVG(total_amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3
FROM sales
WHERE status = 'completed';

-- Running count
SELECT 
    sale_id,
    sale_date,
    customer_id,
    COUNT(*) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date, sale_id
    ) AS order_number
FROM sales;

-- ================================================================
-- SECTION 4: VALUE FUNCTIONS - LAG and LEAD
-- ================================================================

-- LAG - access previous row
SELECT 
    sale_id,
    sale_date,
    total_amount,
    LAG(total_amount) OVER (ORDER BY sale_date, sale_id) AS prev_amount,
    total_amount - LAG(total_amount) OVER (ORDER BY sale_date, sale_id) AS change_from_prev
FROM sales
WHERE status = 'completed';

-- LAG with offset
SELECT 
    sale_id,
    sale_date,
    total_amount,
    LAG(total_amount, 1) OVER (ORDER BY sale_date, sale_id) AS prev_1,
    LAG(total_amount, 2) OVER (ORDER BY sale_date, sale_id) AS prev_2,
    LAG(total_amount, 3) OVER (ORDER BY sale_date, sale_id) AS prev_3
FROM sales
WHERE status = 'completed';

-- LAG with default value
SELECT 
    sale_id,
    sale_date,
    total_amount,
    LAG(total_amount, 1, 0) OVER (ORDER BY sale_date, sale_id) AS prev_amount,
    total_amount - LAG(total_amount, 1, total_amount) OVER (ORDER BY sale_date, sale_id) AS change
FROM sales
WHERE status = 'completed';

-- LEAD - access next row
SELECT 
    sale_id,
    sale_date,
    total_amount,
    LEAD(total_amount) OVER (ORDER BY sale_date, sale_id) AS next_amount,
    LEAD(sale_date) OVER (ORDER BY sale_date, sale_id) AS next_sale_date
FROM sales
WHERE status = 'completed';

-- Calculate time between purchases per customer
SELECT 
    customer_id,
    sale_id,
    sale_date,
    LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date) AS prev_purchase_date,
    DATEDIFF(sale_date, LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) AS days_between_purchases
FROM sales
WHERE status = 'completed'
ORDER BY customer_id, sale_date;

-- ================================================================
-- SECTION 5: FIRST_VALUE and LAST_VALUE
-- ================================================================

-- FIRST_VALUE - get first value in partition
SELECT 
    customer_id,
    sale_id,
    sale_date,
    total_amount,
    FIRST_VALUE(sale_date) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date
    ) AS first_purchase_date,
    FIRST_VALUE(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date
    ) AS first_purchase_amount
FROM sales
WHERE status = 'completed';

-- LAST_VALUE - get last value in partition
-- Note: Need to specify frame for LAST_VALUE
SELECT 
    customer_id,
    sale_id,
    sale_date,
    total_amount,
    LAST_VALUE(total_amount) OVER (
        PARTITION BY customer_id 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_purchase_amount
FROM sales
WHERE status = 'completed';

-- ================================================================
-- SECTION 6: NTH_VALUE
-- ================================================================

-- Get 2nd highest purchase for each customer
SELECT 
    customer_id,
    sale_id,
    sale_date,
    total_amount,
    NTH_VALUE(total_amount, 2) OVER (
        PARTITION BY customer_id 
        ORDER BY total_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS second_highest_purchase
FROM sales
WHERE status = 'completed';

-- ================================================================
-- SECTION 7: WINDOW FRAME SPECIFICATIONS
-- ================================================================

-- Different frame options
SELECT 
    sale_id,
    sale_date,
    total_amount,
    -- All rows from start to current
    SUM(total_amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    -- Last 3 rows
    SUM(total_amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sum_last_3,
    -- 1 before and 1 after
    SUM(total_amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
    ) AS centered_sum,
    -- Current row to end
    SUM(total_amount) OVER (
        ORDER BY sale_date, sale_id
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
    ) AS remaining_total
FROM sales
WHERE status = 'completed';

-- RANGE vs ROWS
-- ROWS: physical row positions
-- RANGE: logical value ranges
SELECT 
    sale_date,
    total_amount,
    SUM(total_amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS sum_rows,
    SUM(total_amount) OVER (
        ORDER BY sale_date
        RANGE BETWEEN INTERVAL 2 DAY PRECEDING AND CURRENT ROW
    ) AS sum_range
FROM sales
WHERE status = 'completed';

-- ================================================================
-- SECTION 8: PERCENT_RANK and CUME_DIST
-- ================================================================

-- PERCENT_RANK - relative rank as percentage
SELECT 
    customer_id,
    name,
    total_spent,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spent) * 100, 2) AS percentile_rank
FROM customers;

-- CUME_DIST - cumulative distribution
SELECT 
    customer_id,
    name,
    total_spent,
    ROUND(CUME_DIST() OVER (ORDER BY total_spent) * 100, 2) AS cumulative_dist_pct
FROM customers;

-- Compare both
SELECT 
    customer_id,
    name,
    total_spent,
    ROW_NUMBER() OVER (ORDER BY total_spent) AS row_num,
    ROUND(PERCENT_RANK() OVER (ORDER BY total_spent) * 100, 2) AS percent_rank,
    ROUND(CUME_DIST() OVER (ORDER BY total_spent) * 100, 2) AS cume_dist
FROM customers;

-- ================================================================
-- SECTION 9: NAMED WINDOWS
-- ================================================================

-- Define window once, use multiple times
SELECT 
    sale_id,
    sale_date,
    total_amount,
    SUM(total_amount) OVER w AS running_total,
    AVG(total_amount) OVER w AS running_avg,
    COUNT(*) OVER w AS running_count
FROM sales
WHERE status = 'completed'
WINDOW w AS (ORDER BY sale_date, sale_id);

-- Multiple named windows
SELECT 
    sale_id,
    customer_id,
    sale_date,
    total_amount,
    ROW_NUMBER() OVER w_all AS overall_row,
    ROW_NUMBER() OVER w_customer AS customer_order_num,
    SUM(total_amount) OVER w_customer AS customer_running_total
FROM sales
WHERE status = 'completed'
WINDOW 
    w_all AS (ORDER BY sale_date, sale_id),
    w_customer AS (PARTITION BY customer_id ORDER BY sale_date, sale_id);

-- ================================================================
-- SECTION 10: PRACTICAL EXAMPLES
-- ================================================================

-- Month-over-month growth
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        SUM(total_amount) AS revenue
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY month) AS absolute_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / 
          LAG(revenue) OVER (ORDER BY month) * 100, 2) AS pct_change
FROM monthly_sales;

-- Customer order sequence analysis
SELECT 
    s.customer_id,
    c.name,
    s.sale_date,
    s.total_amount,
    ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) AS order_number,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) = 1 
        THEN 'First Order'
        ELSE 'Repeat Order'
    END AS order_type,
    DATEDIFF(s.sale_date, 
             FIRST_VALUE(s.sale_date) OVER (PARTITION BY s.customer_id ORDER BY s.sale_date)) AS days_since_first
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.status = 'completed'
ORDER BY s.customer_id, s.sale_date;

-- Product sales comparison to category average
SELECT 
    p.product_id,
    p.name,
    p.category_id,
    COALESCE(SUM(sd.line_total), 0) AS product_revenue,
    AVG(COALESCE(SUM(sd.line_total), 0)) OVER (PARTITION BY p.category_id) AS category_avg_revenue,
    COALESCE(SUM(sd.line_total), 0) - 
        AVG(COALESCE(SUM(sd.line_total), 0)) OVER (PARTITION BY p.category_id) AS diff_from_avg
FROM products p
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
GROUP BY p.product_id, p.name, p.category_id;

-- ================================================================
-- END OF WINDOW FUNCTIONS
-- ================================================================
