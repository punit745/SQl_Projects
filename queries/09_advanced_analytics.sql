-- ================================================================
-- ADVANCED ANALYTICS QUERIES
-- Customer Lifetime Value, Seasonality, Churn, Market Basket
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: CUSTOMER LIFETIME VALUE (CLV) ANALYSIS
-- ================================================================

-- Simple CLV Calculation
SELECT 
    c.customer_id,
    c.name,
    c.email,
    COUNT(s.sale_id) AS total_orders,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_order_value,
    DATEDIFF(MAX(s.sale_date), MIN(s.sale_date)) AS relationship_days,
    DATEDIFF(CURRENT_DATE, c.registration_date) AS days_as_customer
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
GROUP BY c.customer_id, c.name, c.email, c.registration_date
HAVING COUNT(s.sale_id) > 0
ORDER BY total_revenue DESC;

-- Predictive CLV using historical data
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(s.sale_id) AS total_orders,
        SUM(s.total_amount) AS total_revenue,
        AVG(s.total_amount) AS avg_order_value,
        DATEDIFF(MAX(s.sale_date), MIN(s.sale_date)) AS relationship_days,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    GROUP BY c.customer_id, c.name
    HAVING COUNT(s.sale_id) > 1  -- Need at least 2 orders to predict
),
clv_calculation AS (
    SELECT 
        customer_id,
        name,
        total_orders,
        total_revenue,
        avg_order_value,
        relationship_days,
        days_since_last_purchase,
        -- Purchase frequency (orders per day)
        total_orders / NULLIF(relationship_days, 0) AS purchase_frequency_daily,
        -- Estimated annual orders
        (total_orders / NULLIF(relationship_days, 0)) * 365 AS estimated_annual_orders,
        -- Predicted 1-year CLV
        ROUND(avg_order_value * (total_orders / NULLIF(relationship_days, 0)) * 365, 2) AS predicted_1yr_clv,
        -- Predicted 3-year CLV (with 10% annual churn assumed)
        ROUND(avg_order_value * (total_orders / NULLIF(relationship_days, 0)) * 365 * 
              (1 + 0.9 + 0.81), 2) AS predicted_3yr_clv
    FROM customer_metrics
)
SELECT 
    customer_id,
    name,
    total_orders,
    total_revenue AS historical_revenue,
    avg_order_value,
    ROUND(estimated_annual_orders, 2) AS estimated_annual_orders,
    predicted_1yr_clv,
    predicted_3yr_clv,
    CASE 
        WHEN predicted_3yr_clv >= 500000 THEN 'Platinum'
        WHEN predicted_3yr_clv >= 200000 THEN 'Gold'
        WHEN predicted_3yr_clv >= 50000 THEN 'Silver'
        ELSE 'Bronze'
    END AS clv_tier
FROM clv_calculation
ORDER BY predicted_3yr_clv DESC;

-- ================================================================
-- SECTION 2: SEASONALITY ANALYSIS
-- ================================================================

-- Monthly Seasonality
SELECT 
    MONTH(sale_date) AS month_num,
    MONTHNAME(sale_date) AS month_name,
    COUNT(sale_id) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers,
    -- Percentage of annual revenue
    ROUND(SUM(total_amount) * 100.0 / SUM(SUM(total_amount)) OVER(), 2) AS revenue_share_pct
FROM sales
WHERE status = 'completed'
GROUP BY MONTH(sale_date), MONTHNAME(sale_date)
ORDER BY month_num;

-- Quarterly Seasonality
SELECT 
    YEAR(sale_date) AS year,
    QUARTER(sale_date) AS quarter,
    CONCAT('Q', QUARTER(sale_date), ' ', YEAR(sale_date)) AS period,
    COUNT(sale_id) AS order_count,
    SUM(total_amount) AS total_revenue,
    COUNT(DISTINCT customer_id) AS unique_customers,
    -- Quarter-over-Quarter growth
    LAG(SUM(total_amount)) OVER (ORDER BY YEAR(sale_date), QUARTER(sale_date)) AS prev_quarter_revenue,
    ROUND(
        (SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY YEAR(sale_date), QUARTER(sale_date))) * 100.0 /
        NULLIF(LAG(SUM(total_amount)) OVER (ORDER BY YEAR(sale_date), QUARTER(sale_date)), 0)
    , 2) AS qoq_growth_pct
FROM sales
WHERE status = 'completed'
GROUP BY YEAR(sale_date), QUARTER(sale_date)
ORDER BY year, quarter;

-- Day of Week Analysis
SELECT 
    DAYOFWEEK(sale_date) AS day_num,
    DAYNAME(sale_date) AS day_name,
    COUNT(sale_id) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    ROUND(SUM(total_amount) * 100.0 / SUM(SUM(total_amount)) OVER(), 2) AS revenue_share_pct
FROM sales
WHERE status = 'completed'
GROUP BY DAYOFWEEK(sale_date), DAYNAME(sale_date)
ORDER BY day_num;

-- Hour of Day Analysis
SELECT 
    HOUR(sale_date) AS hour_of_day,
    COUNT(sale_id) AS order_count,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM sales
WHERE status = 'completed'
GROUP BY HOUR(sale_date)
ORDER BY hour_of_day;

-- Year-over-Year Monthly Comparison
WITH monthly_sales AS (
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        SUM(total_amount) AS revenue
    FROM sales
    WHERE status = 'completed'
    GROUP BY YEAR(sale_date), MONTH(sale_date)
)
SELECT 
    m1.year,
    m1.month,
    MONTHNAME(MAKEDATE(m1.year, m1.month * 28)) AS month_name,
    m1.revenue AS current_revenue,
    m2.revenue AS prev_year_revenue,
    ROUND((m1.revenue - COALESCE(m2.revenue, 0)) * 100.0 / NULLIF(m2.revenue, 0), 2) AS yoy_growth_pct
FROM monthly_sales m1
LEFT JOIN monthly_sales m2 ON m1.month = m2.month AND m1.year = m2.year + 1
ORDER BY m1.year, m1.month;

-- ================================================================
-- SECTION 3: CHURN PREDICTION AND ANALYSIS
-- ================================================================

-- Customer Churn Status
WITH customer_activity AS (
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.registration_date,
        COUNT(s.sale_id) AS total_orders,
        MAX(s.sale_date) AS last_purchase_date,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase,
        AVG(s.total_amount) AS avg_order_value,
        SUM(s.total_amount) AS total_spent
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    GROUP BY c.customer_id, c.name, c.email, c.registration_date
)
SELECT 
    customer_id,
    name,
    total_orders,
    last_purchase_date,
    days_since_last_purchase,
    avg_order_value,
    total_spent,
    CASE 
        WHEN days_since_last_purchase IS NULL THEN 'Never Purchased'
        WHEN days_since_last_purchase <= 30 THEN 'Active'
        WHEN days_since_last_purchase <= 60 THEN 'At Risk'
        WHEN days_since_last_purchase <= 90 THEN 'Likely Churned'
        ELSE 'Churned'
    END AS churn_status,
    CASE 
        WHEN total_orders = 1 AND days_since_last_purchase > 60 THEN 'One-time Buyer'
        WHEN total_orders >= 5 AND days_since_last_purchase > 90 THEN 'Lost Loyal'
        WHEN avg_order_value > 50000 AND days_since_last_purchase > 60 THEN 'High-Value At Risk'
        ELSE 'Standard'
    END AS risk_category
FROM customer_activity
ORDER BY 
    CASE churn_status
        WHEN 'High-Value At Risk' THEN 1
        WHEN 'Lost Loyal' THEN 2
        WHEN 'At Risk' THEN 3
        WHEN 'Likely Churned' THEN 4
        WHEN 'Churned' THEN 5
        ELSE 6
    END;

-- Churn Rate by Cohort
WITH cohort_activity AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(c.registration_date, '%Y-%m') AS cohort_month,
        MAX(s.sale_date) AS last_purchase
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    GROUP BY c.customer_id, DATE_FORMAT(c.registration_date, '%Y-%m')
)
SELECT 
    cohort_month,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN DATEDIFF(CURRENT_DATE, last_purchase) > 90 OR last_purchase IS NULL THEN 1 ELSE 0 END) AS churned_count,
    ROUND(
        SUM(CASE WHEN DATEDIFF(CURRENT_DATE, last_purchase) > 90 OR last_purchase IS NULL THEN 1 ELSE 0 END) * 100.0 / 
        COUNT(*), 2
    ) AS churn_rate_pct
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;

-- Churn Prediction Indicators
WITH customer_behavior AS (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(s.sale_id) AS order_count,
        AVG(s.total_amount) AS avg_order_value,
        STDDEV(s.total_amount) AS order_value_stddev,
        MAX(s.sale_date) AS last_purchase,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_inactive,
        -- Average days between purchases
        CASE 
            WHEN COUNT(s.sale_id) > 1 THEN
                DATEDIFF(MAX(s.sale_date), MIN(s.sale_date)) / (COUNT(s.sale_id) - 1)
            ELSE NULL
        END AS avg_days_between_purchases
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    GROUP BY c.customer_id, c.name
)
SELECT 
    customer_id,
    name,
    order_count,
    avg_order_value,
    avg_days_between_purchases,
    days_inactive,
    -- Churn probability score (0-100)
    LEAST(100, GREATEST(0,
        -- Base score from inactivity
        CASE 
            WHEN days_inactive <= 30 THEN 0
            WHEN days_inactive <= 60 THEN 20
            WHEN days_inactive <= 90 THEN 50
            ELSE 80
        END +
        -- Adjustment for low frequency
        CASE 
            WHEN order_count = 1 THEN 20
            WHEN order_count <= 3 THEN 10
            ELSE 0
        END +
        -- Adjustment for expected purchase overdue
        CASE 
            WHEN avg_days_between_purchases IS NOT NULL 
                 AND days_inactive > avg_days_between_purchases * 2 THEN 20
            ELSE 0
        END
    )) AS churn_probability_score
FROM customer_behavior
ORDER BY churn_probability_score DESC;

-- ================================================================
-- SECTION 4: MARKET BASKET ANALYSIS
-- ================================================================

-- Products Frequently Bought Together
SELECT 
    p1.name AS product_1,
    p2.name AS product_2,
    COUNT(*) AS times_bought_together,
    COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT sale_id) FROM sales) AS support_pct
FROM sales_details sd1
JOIN sales_details sd2 ON sd1.sale_id = sd2.sale_id 
    AND sd1.product_id < sd2.product_id
JOIN products p1 ON sd1.product_id = p1.product_id
JOIN products p2 ON sd2.product_id = p2.product_id
GROUP BY p1.product_id, p1.name, p2.product_id, p2.name
HAVING COUNT(*) >= 1
ORDER BY times_bought_together DESC
LIMIT 20;

-- Association Rules (Simplified)
WITH product_sales AS (
    SELECT 
        product_id,
        COUNT(DISTINCT sale_id) AS sales_count
    FROM sales_details
    GROUP BY product_id
),
pair_sales AS (
    SELECT 
        sd1.product_id AS product_a,
        sd2.product_id AS product_b,
        COUNT(DISTINCT sd1.sale_id) AS together_count
    FROM sales_details sd1
    JOIN sales_details sd2 ON sd1.sale_id = sd2.sale_id 
        AND sd1.product_id < sd2.product_id
    GROUP BY sd1.product_id, sd2.product_id
),
total_transactions AS (
    SELECT COUNT(DISTINCT sale_id) AS total FROM sales
)
SELECT 
    p1.name AS antecedent,
    p2.name AS consequent,
    ps1.sales_count AS antecedent_sales,
    pair.together_count,
    -- Support: How often items appear together
    ROUND(pair.together_count * 100.0 / tt.total, 2) AS support_pct,
    -- Confidence: If A is purchased, how likely is B
    ROUND(pair.together_count * 100.0 / ps1.sales_count, 2) AS confidence_pct,
    -- Lift: How much more likely is B when A is purchased
    ROUND(
        (pair.together_count * tt.total) / (ps1.sales_count * ps2.sales_count * 1.0), 
        2
    ) AS lift
FROM pair_sales pair
JOIN products p1 ON pair.product_a = p1.product_id
JOIN products p2 ON pair.product_b = p2.product_id
JOIN product_sales ps1 ON pair.product_a = ps1.product_id
JOIN product_sales ps2 ON pair.product_b = ps2.product_id
CROSS JOIN total_transactions tt
WHERE pair.together_count >= 1
ORDER BY lift DESC, support_pct DESC;

-- Category Affinity
SELECT 
    c1.category_name AS category_1,
    c2.category_name AS category_2,
    COUNT(DISTINCT sd1.sale_id) AS times_bought_together
FROM sales_details sd1
JOIN sales_details sd2 ON sd1.sale_id = sd2.sale_id 
    AND sd1.product_id != sd2.product_id
JOIN products p1 ON sd1.product_id = p1.product_id
JOIN products p2 ON sd2.product_id = p2.product_id
JOIN categories c1 ON p1.category_id = c1.category_id
JOIN categories c2 ON p2.category_id = c2.category_id
WHERE c1.category_id < c2.category_id  -- Avoid duplicates
GROUP BY c1.category_id, c1.category_name, c2.category_id, c2.category_name
ORDER BY times_bought_together DESC;

-- ================================================================
-- SECTION 5: PURCHASE PATTERN ANALYSIS
-- ================================================================

-- Repeat Purchase Rate
WITH first_purchases AS (
    SELECT 
        customer_id,
        MIN(sale_date) AS first_purchase_date
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
),
repeat_purchases AS (
    SELECT 
        fp.customer_id,
        COUNT(s.sale_id) AS subsequent_orders
    FROM first_purchases fp
    JOIN sales s ON fp.customer_id = s.customer_id 
        AND s.sale_date > fp.first_purchase_date
        AND s.status = 'completed'
    GROUP BY fp.customer_id
)
SELECT 
    COUNT(DISTINCT fp.customer_id) AS total_customers,
    COUNT(DISTINCT rp.customer_id) AS repeat_customers,
    ROUND(COUNT(DISTINCT rp.customer_id) * 100.0 / COUNT(DISTINCT fp.customer_id), 2) AS repeat_purchase_rate,
    AVG(rp.subsequent_orders) AS avg_repeat_orders
FROM first_purchases fp
LEFT JOIN repeat_purchases rp ON fp.customer_id = rp.customer_id;

-- Purchase Frequency Distribution
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count
    FROM sales
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 orders'
        ELSE '10+ orders'
    END AS frequency_bucket,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM customer_orders
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count BETWEEN 2 AND 3 THEN '2-3 orders'
        WHEN order_count BETWEEN 4 AND 6 THEN '4-6 orders'
        WHEN order_count BETWEEN 7 AND 10 THEN '7-10 orders'
        ELSE '10+ orders'
    END
ORDER BY MIN(order_count);

-- ================================================================
-- END OF ADVANCED ANALYTICS
-- ================================================================
