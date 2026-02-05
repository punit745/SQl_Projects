-- ================================================================
-- SQL FEATURE ENGINEERING FOR MACHINE LEARNING
-- Preparing features from database for ML models
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: CUSTOMER FEATURES
-- ================================================================

-- Create customer features view for ML
CREATE OR REPLACE VIEW vw_ml_customer_features AS
SELECT 
    c.customer_id,
    
    -- Demographic features
    TIMESTAMPDIFF(MONTH, c.registration_date, CURRENT_DATE) AS months_as_customer,
    c.tier_id,
    
    -- Monetary features (RFM - Monetary)
    c.total_spent,
    COALESCE(s.avg_order_value, 0) AS avg_order_value,
    COALESCE(s.max_order_value, 0) AS max_order_value,
    COALESCE(s.min_order_value, 0) AS min_order_value,
    COALESCE(s.std_order_value, 0) AS std_order_value,
    
    -- Frequency features (RFM - Frequency)
    COALESCE(s.total_orders, 0) AS total_orders,
    COALESCE(s.avg_days_between_orders, 0) AS avg_days_between_orders,
    
    -- Recency features (RFM - Recency)
    COALESCE(DATEDIFF(CURRENT_DATE, s.last_order_date), 9999) AS days_since_last_order,
    COALESCE(DATEDIFF(CURRENT_DATE, s.first_order_date), 0) AS days_since_first_order,
    
    -- Behavioral features
    COALESCE(s.unique_products, 0) AS unique_products_purchased,
    COALESCE(s.unique_categories, 0) AS unique_categories_purchased,
    COALESCE(s.total_items, 0) AS total_items_purchased,
    COALESCE(s.avg_items_per_order, 0) AS avg_items_per_order,
    
    -- Trend features
    COALESCE(recent.recent_orders, 0) AS orders_last_90_days,
    COALESCE(recent.recent_spending, 0) AS spending_last_90_days,
    
    -- Target variable candidates
    IF(DATEDIFF(CURRENT_DATE, s.last_order_date) > 180, 1, 0) AS is_churned,
    c.total_spent / NULLIF(TIMESTAMPDIFF(MONTH, c.registration_date, CURRENT_DATE), 0) AS monthly_revenue
    
FROM customers c
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS total_orders,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value,
        MAX(total_amount) AS max_order_value,
        MIN(total_amount) AS min_order_value,
        STDDEV(total_amount) AS std_order_value,
        MAX(sale_date) AS last_order_date,
        MIN(sale_date) AS first_order_date,
        AVG(days_diff) AS avg_days_between_orders
    FROM (
        SELECT 
            customer_id,
            total_amount,
            sale_date,
            DATEDIFF(sale_date, LAG(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) AS days_diff
        FROM sales
        WHERE status = 'completed'
    ) sale_diffs
    GROUP BY customer_id
) s ON c.customer_id = s.customer_id
LEFT JOIN (
    SELECT 
        s.customer_id,
        COUNT(DISTINCT sd.product_id) AS unique_products,
        COUNT(DISTINCT p.category_id) AS unique_categories,
        SUM(sd.quantity) AS total_items,
        AVG(sd.quantity) AS avg_items_per_order
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    JOIN products p ON sd.product_id = p.product_id
    WHERE s.status = 'completed'
    GROUP BY s.customer_id
) prod ON c.customer_id = prod.customer_id
LEFT JOIN (
    SELECT 
        customer_id,
        COUNT(*) AS recent_orders,
        SUM(total_amount) AS recent_spending
    FROM sales
    WHERE status = 'completed'
      AND sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY customer_id
) recent ON c.customer_id = recent.customer_id;

-- ================================================================
-- SECTION 2: PRODUCT FEATURES
-- ================================================================

CREATE OR REPLACE VIEW vw_ml_product_features AS
SELECT 
    p.product_id,
    
    -- Basic features
    p.category_id,
    p.price,
    p.cost_price,
    p.price - COALESCE(p.cost_price, 0) AS profit_margin,
    (p.price - COALESCE(p.cost_price, 0)) / NULLIF(p.price, 0) * 100 AS profit_margin_pct,
    
    -- Inventory features
    p.stock,
    p.reorder_level,
    p.stock / NULLIF(p.reorder_level, 0) AS stock_ratio,
    CASE 
        WHEN p.stock = 0 THEN 1 
        ELSE 0 
    END AS is_out_of_stock,
    
    -- Sales features
    COALESCE(s.total_units_sold, 0) AS total_units_sold,
    COALESCE(s.total_revenue, 0) AS total_revenue,
    COALESCE(s.total_orders, 0) AS times_ordered,
    COALESCE(s.unique_customers, 0) AS unique_customers,
    COALESCE(s.avg_quantity_per_order, 0) AS avg_quantity_per_order,
    
    -- Time features
    COALESCE(DATEDIFF(CURRENT_DATE, s.first_sale_date), 0) AS days_since_first_sale,
    COALESCE(DATEDIFF(CURRENT_DATE, s.last_sale_date), 9999) AS days_since_last_sale,
    
    -- Velocity features
    COALESCE(s.total_units_sold / NULLIF(DATEDIFF(CURRENT_DATE, s.first_sale_date), 0), 0) AS daily_sales_velocity,
    
    -- Recent trends
    COALESCE(recent.recent_units, 0) AS units_sold_last_30_days,
    COALESCE(recent.recent_revenue, 0) AS revenue_last_30_days,
    
    -- Category rank
    RANK() OVER (PARTITION BY p.category_id ORDER BY COALESCE(s.total_revenue, 0) DESC) AS category_revenue_rank
    
FROM products p
LEFT JOIN (
    SELECT 
        sd.product_id,
        SUM(sd.quantity) AS total_units_sold,
        SUM(sd.line_total) AS total_revenue,
        COUNT(DISTINCT s.sale_id) AS total_orders,
        COUNT(DISTINCT s.customer_id) AS unique_customers,
        AVG(sd.quantity) AS avg_quantity_per_order,
        MIN(s.sale_date) AS first_sale_date,
        MAX(s.sale_date) AS last_sale_date
    FROM sales_details sd
    JOIN sales s ON sd.sale_id = s.sale_id
    WHERE s.status = 'completed'
    GROUP BY sd.product_id
) s ON p.product_id = s.product_id
LEFT JOIN (
    SELECT 
        sd.product_id,
        SUM(sd.quantity) AS recent_units,
        SUM(sd.line_total) AS recent_revenue
    FROM sales_details sd
    JOIN sales s ON sd.sale_id = s.sale_id
    WHERE s.status = 'completed'
      AND s.sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
    GROUP BY sd.product_id
) recent ON p.product_id = recent.product_id;

-- ================================================================
-- SECTION 3: TIME SERIES FEATURES
-- ================================================================

-- Daily sales features for time series forecasting
CREATE OR REPLACE VIEW vw_ml_daily_sales_features AS
WITH daily_sales AS (
    SELECT 
        DATE(sale_date) AS sale_date,
        COUNT(*) AS order_count,
        SUM(total_amount) AS revenue,
        AVG(total_amount) AS avg_order_value,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE(sale_date)
)
SELECT 
    ds.sale_date,
    
    -- Target variable
    ds.revenue,
    ds.order_count,
    
    -- Calendar features
    DAYOFWEEK(ds.sale_date) AS day_of_week,
    DAY(ds.sale_date) AS day_of_month,
    WEEK(ds.sale_date) AS week_of_year,
    MONTH(ds.sale_date) AS month,
    QUARTER(ds.sale_date) AS quarter,
    YEAR(ds.sale_date) AS year,
    
    -- Boolean flags
    IF(DAYOFWEEK(ds.sale_date) IN (1, 7), 1, 0) AS is_weekend,
    IF(DAY(ds.sale_date) IN (1, 15), 1, 0) AS is_pay_day,
    IF(MONTH(ds.sale_date) = 12 AND DAY(ds.sale_date) > 15, 1, 0) AS is_holiday_season,
    
    -- Lag features
    LAG(ds.revenue, 1) OVER (ORDER BY ds.sale_date) AS revenue_lag_1,
    LAG(ds.revenue, 7) OVER (ORDER BY ds.sale_date) AS revenue_lag_7,
    LAG(ds.revenue, 30) OVER (ORDER BY ds.sale_date) AS revenue_lag_30,
    
    -- Moving averages
    AVG(ds.revenue) OVER (
        ORDER BY ds.sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_ma_7,
    AVG(ds.revenue) OVER (
        ORDER BY ds.sale_date 
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS revenue_ma_30,
    
    -- Standard deviation (volatility)
    STDDEV(ds.revenue) OVER (
        ORDER BY ds.sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_std_7,
    
    -- Growth rate
    (ds.revenue - LAG(ds.revenue, 1) OVER (ORDER BY ds.sale_date)) / 
        NULLIF(LAG(ds.revenue, 1) OVER (ORDER BY ds.sale_date), 0) * 100 AS revenue_growth_pct,
        
    -- Cumulative features
    SUM(ds.revenue) OVER (
        PARTITION BY YEAR(ds.sale_date), MONTH(ds.sale_date)
        ORDER BY ds.sale_date
    ) AS mtd_revenue
    
FROM daily_sales ds
ORDER BY ds.sale_date;

-- ================================================================
-- SECTION 4: BASKET ANALYSIS FEATURES
-- ================================================================

-- Product co-occurrence features
CREATE OR REPLACE VIEW vw_ml_product_affinity AS
SELECT 
    a.product_id AS product_a,
    b.product_id AS product_b,
    COUNT(*) AS co_occurrence_count,
    COUNT(*) / (SELECT COUNT(DISTINCT sale_id) FROM sales WHERE status = 'completed') AS co_occurrence_rate
FROM sales_details a
JOIN sales_details b ON a.sale_id = b.sale_id AND a.product_id < b.product_id
JOIN sales s ON a.sale_id = s.sale_id
WHERE s.status = 'completed'
GROUP BY a.product_id, b.product_id
HAVING COUNT(*) >= 2
ORDER BY co_occurrence_count DESC;

-- ================================================================
-- SECTION 5: FEATURE EXPORT PROCEDURES
-- ================================================================

DELIMITER //

-- Export customer features to CSV format
CREATE PROCEDURE sp_export_customer_features()
BEGIN
    SELECT 
        'customer_id', 'months_as_customer', 'tier_id', 'total_spent', 
        'avg_order_value', 'total_orders', 'days_since_last_order',
        'unique_products_purchased', 'is_churned'
    UNION ALL
    SELECT 
        customer_id, months_as_customer, tier_id, total_spent,
        ROUND(avg_order_value, 2), total_orders, days_since_last_order,
        unique_products_purchased, is_churned
    FROM vw_ml_customer_features
    INTO OUTFILE '/tmp/customer_features.csv'
    FIELDS TERMINATED BY ','
    ENCLOSED BY '"'
    LINES TERMINATED BY '\n';
END //

-- Generate feature statistics
CREATE PROCEDURE sp_feature_statistics()
BEGIN
    -- Customer feature stats
    SELECT 
        'Customer Features' AS feature_set,
        COUNT(*) AS total_records,
        AVG(total_spent) AS avg_total_spent,
        AVG(total_orders) AS avg_total_orders,
        AVG(days_since_last_order) AS avg_recency,
        SUM(is_churned) / COUNT(*) * 100 AS churn_rate_pct
    FROM vw_ml_customer_features;
    
    -- Product feature stats
    SELECT 
        'Product Features' AS feature_set,
        COUNT(*) AS total_records,
        AVG(total_units_sold) AS avg_units_sold,
        AVG(total_revenue) AS avg_revenue,
        SUM(is_out_of_stock) / COUNT(*) * 100 AS out_of_stock_pct
    FROM vw_ml_product_features;
END //

-- Create normalized features
CREATE PROCEDURE sp_create_normalized_features()
BEGIN
    -- Create temporary table with normalized customer features
    DROP TEMPORARY TABLE IF EXISTS tmp_normalized_customer_features;
    
    CREATE TEMPORARY TABLE tmp_normalized_customer_features AS
    WITH stats AS (
        SELECT 
            AVG(total_spent) AS mean_spent,
            STDDEV(total_spent) AS std_spent,
            AVG(total_orders) AS mean_orders,
            STDDEV(total_orders) AS std_orders,
            AVG(days_since_last_order) AS mean_recency,
            STDDEV(days_since_last_order) AS std_recency
        FROM vw_ml_customer_features
    )
    SELECT 
        f.customer_id,
        (f.total_spent - s.mean_spent) / NULLIF(s.std_spent, 0) AS z_total_spent,
        (f.total_orders - s.mean_orders) / NULLIF(s.std_orders, 0) AS z_total_orders,
        (f.days_since_last_order - s.mean_recency) / NULLIF(s.std_recency, 0) AS z_recency,
        f.is_churned
    FROM vw_ml_customer_features f
    CROSS JOIN stats s;
    
    SELECT * FROM tmp_normalized_customer_features;
END //

DELIMITER ;

-- ================================================================
-- SECTION 6: SAMPLE QUERIES FOR ML PIPELINES
-- ================================================================

-- Get training data for churn prediction
/*
SELECT *
FROM vw_ml_customer_features
WHERE customer_id NOT IN (
    -- Exclude recent customers with insufficient history
    SELECT customer_id FROM customers 
    WHERE registration_date > DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
);
*/

-- Get product recommendation candidates
/*
SELECT 
    c.customer_id,
    p.product_id,
    -- Features for recommendation
    COUNT(DISTINCT past.product_id) AS products_bought,
    MAX(past.recency) AS best_recency_score,
    -- Already purchased flag (negative label)
    MAX(IF(past.product_id = p.product_id, 1, 0)) AS already_purchased
FROM customers c
CROSS JOIN products p
LEFT JOIN (
    SELECT 
        s.customer_id,
        sd.product_id,
        1 / (1 + DATEDIFF(CURRENT_DATE, s.sale_date)) AS recency_score,
        s.sale_date
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    WHERE s.status = 'completed'
) past ON c.customer_id = past.customer_id
GROUP BY c.customer_id, p.product_id;
*/

-- ================================================================
-- END OF FEATURE ENGINEERING
-- ================================================================
