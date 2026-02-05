-- ================================================================
-- FORECASTING QUERIES
-- Time series forecasting with SQL
-- ================================================================

USE retail_sales_advanced;

-- Simple moving average forecast
WITH daily_sales AS (
    SELECT DATE(sale_date) AS sale_date, SUM(total_amount) AS revenue
    FROM sales WHERE status = 'completed'
    GROUP BY DATE(sale_date)
)
SELECT 
    sale_date,
    revenue,
    AVG(revenue) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS forecast_ma7,
    AVG(revenue) OVER (ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS forecast_ma30
FROM daily_sales ORDER BY sale_date DESC LIMIT 30;

-- Exponential smoothing simulation
WITH RECURSIVE daily_sales AS (
    SELECT DATE(sale_date) AS sale_date, SUM(total_amount) AS revenue,
           ROW_NUMBER() OVER (ORDER BY DATE(sale_date)) AS rn
    FROM sales WHERE status = 'completed'
    GROUP BY DATE(sale_date)
),
ema AS (
    SELECT sale_date, revenue, rn, revenue AS ema_value FROM daily_sales WHERE rn = 1
    UNION ALL
    SELECT ds.sale_date, ds.revenue, ds.rn,
           0.2 * ds.revenue + 0.8 * e.ema_value AS ema_value
    FROM daily_sales ds
    JOIN ema e ON ds.rn = e.rn + 1
)
SELECT sale_date, revenue, ROUND(ema_value, 2) AS exponential_forecast
FROM ema ORDER BY sale_date DESC LIMIT 30;

-- Seasonal decomposition (monthly patterns)
WITH monthly_sales AS (
    SELECT MONTH(sale_date) AS month, AVG(total_amount) AS avg_revenue
    FROM sales WHERE status = 'completed'
    GROUP BY MONTH(sale_date)
),
overall_avg AS (SELECT AVG(avg_revenue) AS grand_avg FROM monthly_sales)
SELECT 
    m.month,
    ROUND(m.avg_revenue, 2) AS monthly_avg,
    ROUND(m.avg_revenue / o.grand_avg, 3) AS seasonal_index
FROM monthly_sales m CROSS JOIN overall_avg o ORDER BY m.month;

-- Year-over-year growth projection
WITH yearly AS (
    SELECT YEAR(sale_date) AS year, SUM(total_amount) AS revenue
    FROM sales WHERE status = 'completed'
    GROUP BY YEAR(sale_date)
)
SELECT 
    year,
    revenue,
    LAG(revenue) OVER (ORDER BY year) AS prev_year,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY year)) / 
          LAG(revenue) OVER (ORDER BY year) * 100, 2) AS yoy_growth_pct,
    ROUND(revenue * (1 + (revenue - LAG(revenue) OVER (ORDER BY year)) / 
          LAG(revenue) OVER (ORDER BY year)), 2) AS next_year_projection
FROM yearly ORDER BY year;
