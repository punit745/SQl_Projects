-- ================================================================
-- A/B TESTING ANALYSIS
-- Statistical analysis for experiments
-- ================================================================

USE retail_sales_advanced;

-- A/B Test results table
CREATE TABLE IF NOT EXISTS ab_test_results (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(100),
    variant ENUM('control', 'treatment') NOT NULL,
    customer_id INT,
    converted BOOLEAN DEFAULT FALSE,
    revenue DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sample data for A/B test
INSERT INTO ab_test_results (test_name, variant, customer_id, converted, revenue)
SELECT 
    'Checkout Flow Test',
    IF(customer_id % 2 = 0, 'control', 'treatment'),
    customer_id,
    IF(RAND() < IF(customer_id % 2 = 0, 0.10, 0.12), TRUE, FALSE),
    IF(RAND() < IF(customer_id % 2 = 0, 0.10, 0.12), total_amount, 0)
FROM sales LIMIT 1000
ON DUPLICATE KEY UPDATE test_name = test_name;

-- Basic A/B test summary
SELECT 
    variant,
    COUNT(*) AS sample_size,
    SUM(converted) AS conversions,
    ROUND(SUM(converted) / COUNT(*) * 100, 2) AS conversion_rate_pct,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM ab_test_results
WHERE test_name = 'Checkout Flow Test'
GROUP BY variant;

-- Statistical significance calculation (Z-test approximation)
WITH stats AS (
    SELECT 
        variant,
        COUNT(*) AS n,
        SUM(converted) AS conversions,
        SUM(converted) / COUNT(*) AS p
    FROM ab_test_results
    WHERE test_name = 'Checkout Flow Test'
    GROUP BY variant
),
control AS (SELECT * FROM stats WHERE variant = 'control'),
treatment AS (SELECT * FROM stats WHERE variant = 'treatment')
SELECT 
    'Checkout Flow Test' AS test_name,
    ROUND(c.p * 100, 2) AS control_rate,
    ROUND(t.p * 100, 2) AS treatment_rate,
    ROUND((t.p - c.p) * 100, 2) AS lift_pct,
    ROUND((t.p - c.p) / SQRT(c.p * (1 - c.p) / c.n + t.p * (1 - t.p) / t.n), 3) AS z_score,
    CASE 
        WHEN ABS((t.p - c.p) / SQRT(c.p * (1 - c.p) / c.n + t.p * (1 - t.p) / t.n)) > 1.96 
        THEN 'Significant (95%)'
        ELSE 'Not Significant'
    END AS significance
FROM control c, treatment t;

-- Revenue per user analysis
SELECT 
    variant,
    COUNT(*) AS users,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(AVG(revenue), 2) AS arpu,
    ROUND(AVG(IF(converted, revenue, NULL)), 2) AS avg_revenue_converted
FROM ab_test_results
WHERE test_name = 'Checkout Flow Test'
GROUP BY variant;
