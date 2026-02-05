-- ================================================================
-- OLAP QUERIES FOR DATA WAREHOUSE
-- Cube operations, rollup, slice/dice, drill-down/up
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: ROLLUP QUERIES
-- ================================================================

-- Sales rollup by category and year
SELECT 
    COALESCE(dp.category_name, 'ALL CATEGORIES') AS category,
    COALESCE(CAST(dd.year AS CHAR), 'ALL YEARS') AS year,
    SUM(fs.line_total) AS total_revenue,
    COUNT(*) AS transaction_count,
    SUM(fs.quantity) AS units_sold
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dp.category_name, dd.year WITH ROLLUP;

-- Geographic rollup
SELECT 
    COALESCE(dc.state, 'ALL STATES') AS state,
    COALESCE(dc.city, 'ALL CITIES') AS city,
    SUM(fs.line_total) AS revenue,
    COUNT(DISTINCT fs.customer_key) AS unique_customers
FROM fact_sales fs
JOIN dim_customer dc ON fs.customer_key = dc.customer_key
GROUP BY dc.state, dc.city WITH ROLLUP;

-- Time rollup (year > quarter > month)
SELECT 
    COALESCE(CAST(dd.year AS CHAR), 'TOTAL') AS year,
    COALESCE(CONCAT('Q', dd.quarter), 'ALL QUARTERS') AS quarter,
    COALESCE(dd.month_name, 'ALL MONTHS') AS month,
    SUM(fs.line_total) AS revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.year, dd.quarter, dd.month_name WITH ROLLUP;

-- ================================================================
-- SECTION 2: CUBE QUERIES (Simulated - MySQL doesn't have native CUBE)
-- ================================================================

-- Simulate CUBE with UNION ALL
SELECT 
    category_name,
    year,
    SUM(revenue) AS total_revenue
FROM (
    -- By category and year
    SELECT dp.category_name, dd.year, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    JOIN dim_date dd ON fs.date_key = dd.date_key
    GROUP BY dp.category_name, dd.year
    
    UNION ALL
    
    -- By category only
    SELECT dp.category_name, NULL AS year, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    GROUP BY dp.category_name
    
    UNION ALL
    
    -- By year only
    SELECT NULL AS category_name, dd.year, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_date dd ON fs.date_key = dd.date_key
    GROUP BY dd.year
    
    UNION ALL
    
    -- Grand total
    SELECT NULL AS category_name, NULL AS year, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
) cube_result
GROUP BY category_name, year
ORDER BY category_name, year;

-- ================================================================
-- SECTION 3: SLICE AND DICE
-- ================================================================

-- SLICE: Filter on one dimension (e.g., specific year)
SELECT 
    dp.category_name,
    dc.city,
    SUM(fs.line_total) AS revenue,
    SUM(fs.profit_amount) AS profit
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_customer dc ON fs.customer_key = dc.customer_key
JOIN dim_date dd ON fs.date_key = dd.date_key
WHERE dd.year = 2024  -- SLICE on year
GROUP BY dp.category_name, dc.city
ORDER BY revenue DESC;

-- DICE: Filter on multiple dimensions
SELECT 
    dp.category_name,
    dc.city,
    dd.quarter,
    SUM(fs.line_total) AS revenue
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_customer dc ON fs.customer_key = dc.customer_key
JOIN dim_date dd ON fs.date_key = dd.date_key
WHERE dd.year = 2024                              -- Filter 1
  AND dp.category_name IN ('Electronics', 'Computers')  -- Filter 2
  AND dc.state = 'Maharashtra'                    -- Filter 3
GROUP BY dp.category_name, dc.city, dd.quarter
ORDER BY dd.quarter, revenue DESC;

-- ================================================================
-- SECTION 4: DRILL-DOWN AND DRILL-UP
-- ================================================================

-- DRILL-UP: From daily to monthly to yearly
-- Level 1: Daily view
SELECT 
    dd.full_date,
    SUM(fs.line_total) AS daily_revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
WHERE dd.year = 2024 AND dd.month_number = 1
GROUP BY dd.full_date
ORDER BY dd.full_date;

-- Level 2: Monthly view (drill up from daily)
SELECT 
    dd.year,
    dd.month_name,
    SUM(fs.line_total) AS monthly_revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
WHERE dd.year = 2024
GROUP BY dd.year, dd.month_number, dd.month_name
ORDER BY dd.month_number;

-- Level 3: Yearly view (drill up from monthly)
SELECT 
    dd.year,
    SUM(fs.line_total) AS yearly_revenue
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.year
ORDER BY dd.year;

-- DRILL-DOWN: From category to subcategory to product
-- Level 1: Category view
SELECT 
    dp.category_name,
    SUM(fs.line_total) AS revenue
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category_name
ORDER BY revenue DESC;

-- Level 2: Products within category (drill down)
SELECT 
    dp.category_name,
    dp.name AS product_name,
    SUM(fs.line_total) AS revenue,
    SUM(fs.quantity) AS units_sold
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
WHERE dp.category_name = 'Electronics'  -- Drill into specific category
GROUP BY dp.category_name, dp.product_key, dp.name
ORDER BY revenue DESC;

-- ================================================================
-- SECTION 5: PIVOT TABLE QUERIES
-- ================================================================

-- Monthly trends by category (pivot)
SELECT 
    dp.category_name,
    SUM(CASE WHEN dd.month_number = 1 THEN fs.line_total ELSE 0 END) AS Jan,
    SUM(CASE WHEN dd.month_number = 2 THEN fs.line_total ELSE 0 END) AS Feb,
    SUM(CASE WHEN dd.month_number = 3 THEN fs.line_total ELSE 0 END) AS Mar,
    SUM(CASE WHEN dd.month_number = 4 THEN fs.line_total ELSE 0 END) AS Apr,
    SUM(CASE WHEN dd.month_number = 5 THEN fs.line_total ELSE 0 END) AS May,
    SUM(CASE WHEN dd.month_number = 6 THEN fs.line_total ELSE 0 END) AS Jun,
    SUM(CASE WHEN dd.month_number = 7 THEN fs.line_total ELSE 0 END) AS Jul,
    SUM(CASE WHEN dd.month_number = 8 THEN fs.line_total ELSE 0 END) AS Aug,
    SUM(CASE WHEN dd.month_number = 9 THEN fs.line_total ELSE 0 END) AS Sep,
    SUM(CASE WHEN dd.month_number = 10 THEN fs.line_total ELSE 0 END) AS Oct,
    SUM(CASE WHEN dd.month_number = 11 THEN fs.line_total ELSE 0 END) AS Nov,
    SUM(CASE WHEN dd.month_number = 12 THEN fs.line_total ELSE 0 END) AS `Dec`,
    SUM(fs.line_total) AS Total
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_date dd ON fs.date_key = dd.date_key
WHERE dd.year = 2024
GROUP BY dp.category_name
ORDER BY Total DESC;

-- Day of week analysis pivot
SELECT 
    dp.category_name,
    SUM(CASE WHEN dd.day_name = 'Sunday' THEN fs.line_total ELSE 0 END) AS Sun,
    SUM(CASE WHEN dd.day_name = 'Monday' THEN fs.line_total ELSE 0 END) AS Mon,
    SUM(CASE WHEN dd.day_name = 'Tuesday' THEN fs.line_total ELSE 0 END) AS Tue,
    SUM(CASE WHEN dd.day_name = 'Wednesday' THEN fs.line_total ELSE 0 END) AS Wed,
    SUM(CASE WHEN dd.day_name = 'Thursday' THEN fs.line_total ELSE 0 END) AS Thu,
    SUM(CASE WHEN dd.day_name = 'Friday' THEN fs.line_total ELSE 0 END) AS Fri,
    SUM(CASE WHEN dd.day_name = 'Saturday' THEN fs.line_total ELSE 0 END) AS Sat
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dp.category_name;

-- ================================================================
-- SECTION 6: COMPARATIVE ANALYSIS
-- ================================================================

-- Year-over-Year comparison
SELECT 
    current_year.category_name,
    current_year.revenue AS current_revenue,
    previous_year.revenue AS previous_revenue,
    current_year.revenue - COALESCE(previous_year.revenue, 0) AS yoy_change,
    ROUND((current_year.revenue - COALESCE(previous_year.revenue, 0)) / 
          NULLIF(previous_year.revenue, 0) * 100, 2) AS yoy_pct_change
FROM (
    SELECT dp.category_name, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    JOIN dim_date dd ON fs.date_key = dd.date_key
    WHERE dd.year = 2024
    GROUP BY dp.category_name
) current_year
LEFT JOIN (
    SELECT dp.category_name, SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    JOIN dim_date dd ON fs.date_key = dd.date_key
    WHERE dd.year = 2023
    GROUP BY dp.category_name
) previous_year ON current_year.category_name = previous_year.category_name
ORDER BY yoy_change DESC;

-- Period-over-Period (current quarter vs previous quarter)
WITH quarterly_sales AS (
    SELECT 
        dd.year,
        dd.quarter,
        SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_date dd ON fs.date_key = dd.date_key
    GROUP BY dd.year, dd.quarter
)
SELECT 
    curr.year,
    curr.quarter,
    curr.revenue AS current_revenue,
    prev.revenue AS previous_revenue,
    curr.revenue - COALESCE(prev.revenue, 0) AS qoq_change,
    ROUND((curr.revenue - COALESCE(prev.revenue, 0)) / 
          NULLIF(prev.revenue, 0) * 100, 2) AS qoq_pct_change
FROM quarterly_sales curr
LEFT JOIN quarterly_sales prev ON 
    (curr.year = prev.year AND curr.quarter = prev.quarter + 1)
    OR (curr.year = prev.year + 1 AND curr.quarter = 1 AND prev.quarter = 4)
ORDER BY curr.year, curr.quarter;

-- ================================================================
-- SECTION 7: RANKING AND TOP-N ANALYSIS
-- ================================================================

-- Top 10 products by revenue with running total
SELECT 
    dp.name AS product_name,
    dp.category_name,
    SUM(fs.line_total) AS revenue,
    SUM(SUM(fs.line_total)) OVER (ORDER BY SUM(fs.line_total) DESC) AS running_total,
    ROUND(SUM(fs.line_total) * 100.0 / 
          SUM(SUM(fs.line_total)) OVER (), 2) AS pct_of_total,
    ROUND(SUM(SUM(fs.line_total)) OVER (ORDER BY SUM(fs.line_total) DESC) * 100.0 / 
          SUM(SUM(fs.line_total)) OVER (), 2) AS cumulative_pct
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.name, dp.category_name
ORDER BY revenue DESC
LIMIT 10;

-- Bottom 10 performing products
SELECT 
    dp.name AS product_name,
    dp.category_name,
    SUM(fs.line_total) AS revenue,
    SUM(fs.quantity) AS units_sold
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.name, dp.category_name
ORDER BY revenue ASC
LIMIT 10;

-- ================================================================
-- SECTION 8: MOVING AVERAGES AND TRENDS
-- ================================================================

-- 7-day moving average
SELECT 
    dd.full_date,
    SUM(fs.line_total) AS daily_revenue,
    AVG(SUM(fs.line_total)) OVER (
        ORDER BY dd.full_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day
FROM fact_sales fs
JOIN dim_date dd ON fs.date_key = dd.date_key
GROUP BY dd.date_key, dd.full_date
ORDER BY dd.full_date;

-- Month-to-date vs previous month-to-date
WITH daily_sales AS (
    SELECT 
        dd.year,
        dd.month_number,
        dd.day_of_month,
        SUM(fs.line_total) AS revenue
    FROM fact_sales fs
    JOIN dim_date dd ON fs.date_key = dd.date_key
    GROUP BY dd.year, dd.month_number, dd.day_of_month
)
SELECT 
    curr.day_of_month,
    curr.revenue AS current_month_daily,
    SUM(curr.revenue) OVER (ORDER BY curr.day_of_month) AS current_mtd,
    prev.revenue AS previous_month_daily,
    SUM(prev.revenue) OVER (ORDER BY prev.day_of_month) AS previous_mtd
FROM daily_sales curr
LEFT JOIN daily_sales prev ON 
    curr.day_of_month = prev.day_of_month
    AND curr.year = prev.year
    AND curr.month_number = prev.month_number + 1
WHERE curr.year = 2024 AND curr.month_number = 2
ORDER BY curr.day_of_month;

-- ================================================================
-- SECTION 9: CONTRIBUTION ANALYSIS
-- ================================================================

-- Category contribution to total revenue
SELECT 
    dp.category_name,
    SUM(fs.line_total) AS revenue,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.line_total) * 100.0 / 
          (SELECT SUM(line_total) FROM fact_sales), 2) AS revenue_contribution_pct,
    ROUND(SUM(fs.profit_amount) * 100.0 / 
          (SELECT SUM(profit_amount) FROM fact_sales), 2) AS profit_contribution_pct
FROM fact_sales fs
JOIN dim_product dp ON fs.product_key = dp.product_key
GROUP BY dp.category_name
ORDER BY revenue DESC;

-- Pareto analysis (80/20 rule)
WITH product_revenue AS (
    SELECT 
        dp.name AS product_name,
        SUM(fs.line_total) AS revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(fs.line_total) DESC) AS rank_num
    FROM fact_sales fs
    JOIN dim_product dp ON fs.product_key = dp.product_key
    GROUP BY dp.product_key, dp.name
),
total_revenue AS (
    SELECT SUM(revenue) AS total FROM product_revenue
)
SELECT 
    pr.product_name,
    pr.revenue,
    pr.rank_num,
    ROUND(SUM(pr.revenue) OVER (ORDER BY pr.rank_num) * 100.0 / tr.total, 2) AS cumulative_pct,
    CASE 
        WHEN SUM(pr.revenue) OVER (ORDER BY pr.rank_num) * 100.0 / tr.total <= 80 THEN 'Top 80%'
        ELSE 'Bottom 20%'
    END AS pareto_group
FROM product_revenue pr
CROSS JOIN total_revenue tr
ORDER BY pr.rank_num;

-- ================================================================
-- END OF OLAP QUERIES
-- ================================================================
