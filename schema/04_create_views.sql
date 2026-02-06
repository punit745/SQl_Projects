-- ================================================================
-- VIEW CREATION SCRIPT
-- Creates all views for simplified data access
-- Run after: 02_create_tables.sql
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SALES VIEWS
-- ================================================================

-- View: Complete Sales Summary with Customer and Employee Details
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT 
    s.sale_id,
    s.sale_date,
    DATE(s.sale_date) AS sale_date_only,
    TIME(s.sale_date) AS sale_time,
    YEAR(s.sale_date) AS sale_year,
    MONTH(s.sale_date) AS sale_month,
    QUARTER(s.sale_date) AS sale_quarter,
    DAYNAME(s.sale_date) AS day_of_week,
    c.customer_id,
    c.name AS customer_name,
    c.email AS customer_email,
    c.city,
    c.state,
    c.tier_id,
    ct.tier_name,
    ct.discount_percentage AS tier_discount,
    e.employee_id,
    e.name AS employee_name,
    e.department,
    pm.method_name AS payment_method,
    s.subtotal,
    s.discount_amount,
    s.tax_amount,
    s.shipping_amount,
    s.total_amount,
    s.status
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
LEFT JOIN employees e ON s.employee_id = e.employee_id
LEFT JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id;

-- View: Sales Details with Product Information
CREATE OR REPLACE VIEW vw_sales_details_full AS
SELECT 
    sd.sale_detail_id,
    sd.sale_id,
    s.sale_date,
    s.customer_id,
    c.name AS customer_name,
    sd.product_id,
    p.name AS product_name,
    p.sku,
    cat.category_name,
    sd.quantity,
    sd.unit_price,
    sd.discount,
    sd.line_total,
    p.cost_price,
    (sd.line_total - (p.cost_price * sd.quantity)) AS profit
FROM sales_details sd
JOIN sales s ON sd.sale_id = s.sale_id
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON sd.product_id = p.product_id
LEFT JOIN categories cat ON p.category_id = cat.category_id;

-- View: Daily Sales Summary
CREATE OR REPLACE VIEW vw_daily_sales AS
SELECT 
    DATE(sale_date) AS sale_date,
    COUNT(DISTINCT sale_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value,
    MIN(total_amount) AS min_order_value,
    MAX(total_amount) AS max_order_value
FROM sales
WHERE status = 'completed'
GROUP BY DATE(sale_date);

-- View: Monthly Sales Summary
CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT 
    YEAR(sale_date) AS sale_year,
    MONTH(sale_date) AS sale_month,
    COUNT(DISTINCT sale_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM sales
WHERE status = 'completed'
GROUP BY YEAR(sale_date), MONTH(sale_date);

-- ================================================================
-- PRODUCT VIEWS
-- ================================================================

-- View: Product Sales Performance
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.name AS product_name,
    p.sku,
    cat.category_name,
    p.price AS current_price,
    p.cost_price,
    p.stock AS current_stock,
    p.reorder_level,
    CASE 
        WHEN p.stock = 0 THEN 'Out of Stock'
        WHEN p.stock <= p.reorder_level THEN 'Low Stock'
        WHEN p.stock <= p.reorder_level * 2 THEN 'Adequate'
        ELSE 'Well Stocked'
    END AS stock_status,
    COUNT(sd.sale_detail_id) AS times_sold,
    COALESCE(SUM(sd.quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(sd.line_total), 0) AS total_revenue,
    COALESCE(AVG(sd.line_total), 0) AS avg_sale_value,
    COALESCE(SUM(sd.line_total) - SUM(p.cost_price * sd.quantity), 0) AS total_profit,
    CASE 
        WHEN p.cost_price > 0 THEN ROUND(((p.price - p.cost_price) / p.price) * 100, 2)
        ELSE 0 
    END AS profit_margin_pct
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id AND s.status = 'completed'
GROUP BY p.product_id, p.name, p.sku, cat.category_name, p.price, p.cost_price, p.stock, p.reorder_level;

-- View: Category Performance
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT 
    cat.category_id,
    cat.category_name,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT sd.sale_id) AS order_count,
    COALESCE(SUM(sd.quantity), 0) AS total_units_sold,
    COALESCE(SUM(sd.line_total), 0) AS total_revenue,
    COALESCE(AVG(sd.line_total), 0) AS avg_line_value
FROM categories cat
LEFT JOIN products p ON cat.category_id = p.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN sales s ON sd.sale_id = s.sale_id AND s.status = 'completed'
GROUP BY cat.category_id, cat.category_name;

-- View: Products Needing Reorder
CREATE OR REPLACE VIEW vw_products_reorder AS
SELECT 
    p.product_id,
    p.name,
    p.sku,
    cat.category_name,
    p.stock AS current_stock,
    p.reorder_level,
    (p.reorder_level * 3) - p.stock AS suggested_order_quantity,
    p.cost_price,
    ((p.reorder_level * 3) - p.stock) * p.cost_price AS estimated_order_cost
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.category_id
WHERE p.stock <= p.reorder_level
    AND p.is_active = TRUE
ORDER BY p.stock ASC;

-- ================================================================
-- CUSTOMER VIEWS
-- ================================================================

-- View: Customer Analytics
CREATE OR REPLACE VIEW vw_customer_analytics AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.phone,
    c.city,
    c.state,
    c.registration_date,
    ct.tier_name,
    ct.discount_percentage,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COALESCE(SUM(s.total_amount), 0) AS lifetime_value,
    COALESCE(AVG(s.total_amount), 0) AS avg_order_value,
    MIN(s.sale_date) AS first_purchase_date,
    MAX(s.sale_date) AS last_purchase_date,
    DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase,
    DATEDIFF(CURRENT_DATE, c.registration_date) AS days_as_customer,
    CASE 
        WHEN DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) IS NULL THEN 'Never Purchased'
        WHEN DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) <= 30 THEN 'Active'
        WHEN DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) <= 60 THEN 'At Risk'
        WHEN DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) <= 90 THEN 'Dormant'
        ELSE 'Churned'
    END AS engagement_status
FROM customers c
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.name, c.email, c.phone, c.city, c.state, 
         c.registration_date, ct.tier_name, ct.discount_percentage;

-- View: Customer Segments
CREATE OR REPLACE VIEW vw_customer_segments AS
SELECT 
    customer_id,
    name,
    email,
    lifetime_value,
    total_orders,
    avg_order_value,
    days_since_last_purchase,
    engagement_status,
    CASE 
        WHEN lifetime_value >= 100000 THEN 'VIP'
        WHEN lifetime_value >= 50000 THEN 'Premium'
        WHEN lifetime_value >= 20000 THEN 'Regular'
        WHEN lifetime_value > 0 THEN 'Occasional'
        ELSE 'Prospect'
    END AS value_segment,
    CASE 
        WHEN total_orders >= 10 THEN 'Loyal'
        WHEN total_orders >= 5 THEN 'Repeat'
        WHEN total_orders >= 2 THEN 'Returning'
        WHEN total_orders = 1 THEN 'New'
        ELSE 'Prospect'
    END AS frequency_segment
FROM vw_customer_analytics;

-- ================================================================
-- EMPLOYEE VIEWS
-- ================================================================

-- View: Employee Performance
CREATE OR REPLACE VIEW vw_employee_performance AS
SELECT 
    e.employee_id,
    e.name AS employee_name,
    e.position,
    e.department,
    e.hire_date,
    DATEDIFF(CURRENT_DATE, e.hire_date) AS days_employed,
    e.salary,
    e.commission_rate,
    m.name AS manager_name,
    COUNT(DISTINCT s.sale_id) AS total_sales,
    COALESCE(SUM(s.total_amount), 0) AS total_revenue,
    COALESCE(AVG(s.total_amount), 0) AS avg_sale_value,
    COALESCE(SUM(s.total_amount) * e.commission_rate / 100, 0) AS total_commission
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id
LEFT JOIN sales s ON e.employee_id = s.employee_id AND s.status = 'completed'
WHERE e.is_active = TRUE
GROUP BY e.employee_id, e.name, e.position, e.department, e.hire_date, 
         e.salary, e.commission_rate, m.name;

-- View: Employee Hierarchy
CREATE OR REPLACE VIEW vw_employee_hierarchy AS
WITH RECURSIVE emp_hierarchy AS (
    -- Base case: Top-level managers
    SELECT 
        employee_id,
        name,
        position,
        department,
        manager_id,
        1 AS level,
        CAST(name AS CHAR(500)) AS hierarchy_path
    FROM employees
    WHERE manager_id IS NULL AND is_active = TRUE
    
    UNION ALL
    
    -- Recursive case: Employees with managers
    SELECT 
        e.employee_id,
        e.name,
        e.position,
        e.department,
        e.manager_id,
        eh.level + 1,
        CONCAT(eh.hierarchy_path, ' > ', e.name)
    FROM employees e
    INNER JOIN emp_hierarchy eh ON e.manager_id = eh.employee_id
    WHERE e.is_active = TRUE
)
SELECT 
    employee_id,
    CONCAT(REPEAT('  ', level - 1), name) AS indented_name,
    name,
    position,
    department,
    level,
    hierarchy_path
FROM emp_hierarchy
ORDER BY hierarchy_path;

-- ================================================================
-- INVENTORY VIEWS
-- ================================================================

-- View: Inventory Movement Summary
CREATE OR REPLACE VIEW vw_inventory_movement AS
SELECT 
    p.product_id,
    p.name AS product_name,
    p.sku,
    p.stock AS current_stock,
    SUM(CASE WHEN it.transaction_type = 'purchase' THEN it.quantity ELSE 0 END) AS total_purchased,
    SUM(CASE WHEN it.transaction_type = 'sale' THEN ABS(it.quantity) ELSE 0 END) AS total_sold,
    SUM(CASE WHEN it.transaction_type = 'return' THEN it.quantity ELSE 0 END) AS total_returned,
    SUM(CASE WHEN it.transaction_type = 'adjustment' THEN it.quantity ELSE 0 END) AS total_adjusted,
    COUNT(it.transaction_id) AS transaction_count,
    MAX(it.transaction_date) AS last_movement_date
FROM products p
LEFT JOIN inventory_transactions it ON p.product_id = it.product_id
GROUP BY p.product_id, p.name, p.sku, p.stock;

-- ================================================================
-- VERIFICATION
-- ================================================================

SELECT 'All views created successfully!' AS status;

-- List all views
SELECT 
    TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
ORDER BY TABLE_NAME;
