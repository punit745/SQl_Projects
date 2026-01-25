# 📊 Practical SQL Examples & Business Use Cases

This document contains real-world business scenarios and SQL solutions using the retail sales database.

---

## Table of Contents

1. [Sales Analysis](#sales-analysis)
2. [Customer Analytics](#customer-analytics)
3. [Inventory Management](#inventory-management)
4. [Employee Performance](#employee-performance)
5. [Revenue Forecasting](#revenue-forecasting)
6. [Product Recommendations](#product-recommendations)

---

## Sales Analysis

### 📈 Monthly Sales Trends

**Business Question**: What are our monthly sales trends?

```sql
SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    COUNT(DISTINCT sale_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS revenue,
    AVG(total_amount) AS avg_order_value,
    MAX(total_amount) AS largest_order
FROM sales
WHERE sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
ORDER BY month DESC;
```

**Expected Output**: Monthly aggregated sales metrics

### 📊 Sales by Category

**Business Question**: Which product categories generate the most revenue?

```sql
SELECT 
    cat.category_name,
    COUNT(DISTINCT sd.sale_id) AS num_orders,
    SUM(sd.quantity) AS units_sold,
    SUM(sd.line_total) AS total_revenue,
    ROUND(SUM(sd.line_total) * 100.0 / 
          (SELECT SUM(line_total) FROM sales_details), 2) AS revenue_percentage
FROM sales_details sd
JOIN products p ON sd.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
GROUP BY cat.category_id, cat.category_name
ORDER BY total_revenue DESC;
```

**Business Insight**: Helps identify which categories to focus on for marketing

### 🎯 Day of Week Analysis

**Business Question**: Which days have the highest sales?

```sql
SELECT 
    DAYNAME(sale_date) AS day_of_week,
    DAYOFWEEK(sale_date) AS day_num,
    COUNT(*) AS num_sales,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_sale_amount
FROM sales
WHERE status = 'completed'
GROUP BY DAYNAME(sale_date), DAYOFWEEK(sale_date)
ORDER BY day_num;
```

**Business Insight**: Optimize staffing based on busy days

---

## Customer Analytics

### 👥 Customer Lifetime Value (CLV)

**Business Question**: Who are our most valuable customers?

```sql
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.registration_date,
        COUNT(DISTINCT s.sale_id) AS total_orders,
        SUM(s.total_amount) AS lifetime_value,
        AVG(s.total_amount) AS avg_order_value,
        MIN(s.sale_date) AS first_purchase,
        MAX(s.sale_date) AS last_purchase,
        DATEDIFF(MAX(s.sale_date), MIN(s.sale_date)) AS customer_lifespan_days
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.name, c.email, c.registration_date
)
SELECT 
    *,
    CASE 
        WHEN lifetime_value >= 100000 THEN 'VIP'
        WHEN lifetime_value >= 50000 THEN 'Premium'
        WHEN lifetime_value >= 20000 THEN 'Regular'
        ELSE 'New'
    END AS customer_tier,
    CASE
        WHEN customer_lifespan_days > 0 
        THEN ROUND(lifetime_value / customer_lifespan_days * 365, 2)
        ELSE 0
    END AS annual_value_estimate
FROM customer_metrics
ORDER BY lifetime_value DESC;
```

**Business Action**: Create targeted marketing campaigns for each tier

### 🔄 Customer Retention Analysis

**Business Question**: Are customers coming back?

```sql
WITH customer_orders AS (
    SELECT 
        customer_id,
        sale_date,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY sale_date) AS order_number,
        LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date) AS next_order_date
    FROM sales
)
SELECT 
    order_number,
    COUNT(*) AS num_customers,
    AVG(DATEDIFF(next_order_date, sale_date)) AS avg_days_to_next_order,
    COUNT(CASE WHEN next_order_date IS NOT NULL THEN 1 END) AS returned_customers,
    ROUND(COUNT(CASE WHEN next_order_date IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) AS retention_rate
FROM customer_orders
GROUP BY order_number
ORDER BY order_number;
```

**Business Insight**: Understand at which order number customers typically drop off

### 🎯 Customer Segmentation by Purchase Behavior

**Business Question**: How can we segment our customers?

```sql
WITH purchase_behavior AS (
    SELECT 
        c.customer_id,
        c.name,
        COUNT(DISTINCT s.sale_id) AS purchase_frequency,
        SUM(s.total_amount) AS total_spent,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase,
        COUNT(DISTINCT DATE_FORMAT(s.sale_date, '%Y-%m')) AS active_months
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT 
    name,
    purchase_frequency,
    total_spent,
    days_since_last_purchase,
    active_months,
    CASE 
        WHEN days_since_last_purchase <= 30 AND purchase_frequency >= 5 THEN 'Loyal Active'
        WHEN days_since_last_purchase <= 30 AND purchase_frequency < 5 THEN 'New Active'
        WHEN days_since_last_purchase BETWEEN 31 AND 90 AND purchase_frequency >= 3 THEN 'At Risk'
        WHEN days_since_last_purchase > 90 THEN 'Lost'
        ELSE 'One-time Buyer'
    END AS segment,
    CASE
        WHEN days_since_last_purchase <= 30 THEN 'Send loyalty reward'
        WHEN days_since_last_purchase BETWEEN 31 AND 90 THEN 'Send re-engagement offer'
        WHEN days_since_last_purchase > 90 THEN 'Send win-back campaign'
        ELSE 'Send welcome series'
    END AS recommended_action
FROM purchase_behavior
ORDER BY total_spent DESC;
```

**Business Action**: Automated marketing campaigns based on segments

---

## Inventory Management

### 📦 Stock Alert System

**Business Question**: Which products need reordering?

```sql
SELECT 
    p.product_id,
    p.name,
    cat.category_name,
    p.stock AS current_stock,
    p.reorder_level,
    p.stock - p.reorder_level AS stock_vs_reorder,
    COALESCE(SUM(sd.quantity), 0) AS sold_last_30_days,
    COALESCE(SUM(sd.quantity), 0) / 30.0 AS avg_daily_sales,
    CASE
        WHEN p.stock <= 0 THEN 'URGENT: Out of Stock'
        WHEN p.stock <= p.reorder_level THEN 'Reorder Now'
        WHEN p.stock <= p.reorder_level * 1.5 THEN 'Monitor Closely'
        ELSE 'Stock OK'
    END AS stock_status,
    CASE
        WHEN COALESCE(SUM(sd.quantity), 0) / 30.0 > 0 
        THEN ROUND(p.stock / (COALESCE(SUM(sd.quantity), 0) / 30.0), 0)
        ELSE 999
    END AS days_of_stock_remaining
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id 
    AND s.sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
GROUP BY p.product_id, p.name, cat.category_name, p.stock, p.reorder_level
HAVING stock_status != 'Stock OK'
ORDER BY 
    CASE stock_status
        WHEN 'URGENT: Out of Stock' THEN 1
        WHEN 'Reorder Now' THEN 2
        WHEN 'Monitor Closely' THEN 3
        ELSE 4
    END,
    days_of_stock_remaining;
```

**Business Action**: Automated purchase orders for low-stock items

### 📊 Inventory Turnover Rate

**Business Question**: How quickly are we selling our inventory?

```sql
SELECT 
    p.product_id,
    p.name,
    cat.category_name,
    p.cost_price,
    p.stock AS current_stock,
    COALESCE(SUM(sd.quantity), 0) AS units_sold_90_days,
    ROUND(COALESCE(SUM(sd.quantity), 0) / 3, 2) AS avg_monthly_sales,
    CASE 
        WHEN p.stock > 0 AND COALESCE(SUM(sd.quantity), 0) > 0
        THEN ROUND((COALESCE(SUM(sd.quantity), 0) / 3) / p.stock * 100, 2)
        ELSE 0
    END AS monthly_turnover_rate,
    p.stock * p.cost_price AS inventory_value
FROM products p
JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id 
    AND s.sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
GROUP BY p.product_id, p.name, cat.category_name, p.cost_price, p.stock
ORDER BY monthly_turnover_rate DESC;
```

**Business Insight**: Identify slow-moving vs fast-moving inventory

---

## Employee Performance

### 👔 Employee Sales Leaderboard

**Business Question**: Which employees are top performers?

```sql
WITH employee_stats AS (
    SELECT 
        e.employee_id,
        e.name,
        e.position,
        COUNT(DISTINCT s.sale_id) AS total_sales,
        SUM(s.total_amount) AS total_revenue,
        AVG(s.total_amount) AS avg_sale_value,
        COUNT(DISTINCT s.customer_id) AS unique_customers,
        COUNT(DISTINCT DATE(s.sale_date)) AS days_worked
    FROM employees e
    LEFT JOIN sales s ON e.employee_id = s.employee_id
        AND s.sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY)
    GROUP BY e.employee_id, e.name, e.position
)
SELECT 
    name,
    position,
    total_sales,
    total_revenue,
    avg_sale_value,
    unique_customers,
    days_worked,
    ROUND(total_sales / NULLIF(days_worked, 0), 2) AS sales_per_day,
    ROUND(total_revenue / NULLIF(days_worked, 0), 2) AS revenue_per_day,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM employee_stats
WHERE days_worked > 0
ORDER BY total_revenue DESC;
```

**Business Action**: Performance bonuses, training for low performers

### 💰 Commission Calculator

**Business Question**: What are the sales commissions?

```sql
SELECT 
    e.name AS employee_name,
    e.salary AS base_salary,
    COUNT(s.sale_id) AS num_sales,
    SUM(s.total_amount) AS total_sales_value,
    ROUND(SUM(s.total_amount) * 0.02, 2) AS commission_2_percent,
    ROUND(e.salary + SUM(s.total_amount) * 0.02, 2) AS total_compensation
FROM employees e
LEFT JOIN sales s ON e.employee_id = s.employee_id
    AND YEAR(s.sale_date) = YEAR(CURRENT_DATE)
    AND MONTH(s.sale_date) = MONTH(CURRENT_DATE)
GROUP BY e.employee_id, e.name, e.salary
ORDER BY total_compensation DESC;
```

---

## Revenue Forecasting

### 📈 Simple Moving Average Forecast

**Business Question**: What are our projected sales?

```sql
WITH daily_sales AS (
    SELECT 
        DATE(sale_date) AS sale_date,
        SUM(total_amount) AS daily_revenue
    FROM sales
    WHERE sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 60 DAY)
    GROUP BY DATE(sale_date)
),
moving_averages AS (
    SELECT 
        sale_date,
        daily_revenue,
        AVG(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ma_7_day,
        AVG(daily_revenue) OVER (
            ORDER BY sale_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS ma_30_day
    FROM daily_sales
)
SELECT 
    sale_date,
    ROUND(daily_revenue, 2) AS actual_revenue,
    ROUND(ma_7_day, 2) AS forecast_7_day_ma,
    ROUND(ma_30_day, 2) AS forecast_30_day_ma,
    ROUND((daily_revenue - ma_7_day) / ma_7_day * 100, 2) AS variance_from_7day_pct
FROM moving_averages
ORDER BY sale_date DESC
LIMIT 30;
```

**Business Insight**: Set realistic sales targets

---

## Product Recommendations

### 🔗 Frequently Bought Together

**Business Question**: Which products are commonly purchased together?

```sql
SELECT 
    p1.name AS product_a,
    p2.name AS product_b,
    COUNT(*) AS times_bought_together,
    SUM(sd1.quantity + sd2.quantity) AS total_units,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT sale_id) FROM sales_details
    ), 2) AS affinity_percentage
FROM sales_details sd1
JOIN sales_details sd2 
    ON sd1.sale_id = sd2.sale_id 
    AND sd1.product_id < sd2.product_id
JOIN products p1 ON sd1.product_id = p1.product_id
JOIN products p2 ON sd2.product_id = p2.product_id
GROUP BY p1.product_id, p1.name, p2.product_id, p2.name
HAVING COUNT(*) >= 2
ORDER BY times_bought_together DESC, affinity_percentage DESC
LIMIT 20;
```

**Business Action**: Bundle products, cross-sell recommendations

### 🎯 Next Best Product

**Business Question**: What should we recommend to a customer based on their history?

```sql
-- For a specific customer (customer_id = 1)
WITH customer_purchases AS (
    SELECT DISTINCT sd.product_id
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    WHERE s.customer_id = 1
),
similar_customers AS (
    SELECT DISTINCT s.customer_id
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    WHERE sd.product_id IN (SELECT product_id FROM customer_purchases)
        AND s.customer_id != 1
),
recommended_products AS (
    SELECT 
        p.product_id,
        p.name,
        cat.category_name,
        p.price,
        COUNT(DISTINCT s.customer_id) AS bought_by_similar_customers,
        SUM(sd.quantity) AS total_quantity
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    JOIN products p ON sd.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    WHERE s.customer_id IN (SELECT customer_id FROM similar_customers)
        AND sd.product_id NOT IN (SELECT product_id FROM customer_purchases)
    GROUP BY p.product_id, p.name, cat.category_name, p.price
)
SELECT 
    name,
    category_name,
    price,
    bought_by_similar_customers,
    RANK() OVER (ORDER BY bought_by_similar_customers DESC) AS recommendation_rank
FROM recommended_products
ORDER BY bought_by_similar_customers DESC, total_quantity DESC
LIMIT 5;
```

**Business Action**: Personalized product recommendations

---

## Summary

These examples demonstrate how SQL can solve real business problems:

- **Sales Analysis**: Track trends and identify opportunities
- **Customer Analytics**: Understand and segment customers
- **Inventory Management**: Optimize stock levels
- **Employee Performance**: Measure and reward performance
- **Revenue Forecasting**: Plan for the future
- **Product Recommendations**: Increase cross-selling

Each query can be adapted to your specific business needs and extended with additional filters or metrics.

---

<div align="center">

**Ready to implement these in your business?**

Modify the queries for your specific use case!

</div>
