-- ================================================================
-- ADVANCED SQL QUERIES - RETAIL SALES PROJECT
-- Demonstrating Intermediate & Advanced SQL Concepts
-- ================================================================

-- ================================================================
-- SECTION 1: ENHANCED DATABASE SCHEMA
-- ================================================================

-- Drop existing database and recreate with enhanced schema
DROP DATABASE IF EXISTS retail_sales_advanced;
CREATE DATABASE retail_sales_advanced;
USE retail_sales_advanced;

-- Product Categories Table
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enhanced Products Table with Category
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category_id INT,
    price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2),
    stock INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    INDEX idx_category (category_id),
    INDEX idx_price (price)
);

-- Customer Tiers/Levels
CREATE TABLE customer_tiers (
    tier_id INT PRIMARY KEY AUTO_INCREMENT,
    tier_name VARCHAR(50) NOT NULL,
    min_purchases DECIMAL(10, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0
);

-- Enhanced Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    tier_id INT DEFAULT 1,
    registration_date DATE DEFAULT (CURRENT_DATE),
    last_purchase_date DATE,
    total_spent DECIMAL(12, 2) DEFAULT 0,
    FOREIGN KEY (tier_id) REFERENCES customer_tiers(tier_id),
    INDEX idx_email (email),
    INDEX idx_tier (tier_id)
);

-- Employees Table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    position VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(10, 2),
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Payment Methods
CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    method_name VARCHAR(50) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Enhanced Sales Table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    employee_id INT,
    sale_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_method_id INT,
    subtotal DECIMAL(10, 2),
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'completed',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id),
    INDEX idx_customer (customer_id),
    INDEX idx_date (sale_date),
    INDEX idx_status (status)
);

-- Enhanced Sales Details
CREATE TABLE sales_details (
    sale_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(5, 2) DEFAULT 0,
    line_total DECIMAL(10, 2),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_sale (sale_id),
    INDEX idx_product (product_id)
);

-- Inventory Tracking
CREATE TABLE inventory_transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    transaction_type ENUM('purchase', 'sale', 'adjustment', 'return') NOT NULL,
    quantity INT NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ================================================================
-- SECTION 2: SAMPLE DATA INSERTION
-- ================================================================

-- Insert Customer Tiers
INSERT INTO customer_tiers (tier_name, min_purchases, discount_percentage) VALUES
('Bronze', 0, 0),
('Silver', 10000, 5),
('Gold', 50000, 10),
('Platinum', 100000, 15);

-- Insert Categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Computers', 'Laptops, desktops, and computer accessories'),
('Mobile Phones', 'Smartphones and mobile accessories'),
('Home Appliances', 'Kitchen and home appliances'),
('Audio & Video', 'Headphones, speakers, and entertainment systems');

-- Insert Products
INSERT INTO products (name, category_id, price, cost_price, stock, reorder_level) VALUES
('Dell Latitude Laptop', 2, 85000.00, 70000.00, 15, 5),
('HP Desktop PC', 2, 65000.00, 52000.00, 10, 5),
('iPhone 14 Pro', 3, 120000.00, 100000.00, 25, 10),
('Samsung Galaxy S23', 3, 95000.00, 78000.00, 30, 10),
('Sony Headphones WH-1000XM5', 5, 29000.00, 22000.00, 40, 15),
('LG 65" 4K TV', 5, 85000.00, 68000.00, 12, 5),
('Samsung Refrigerator', 4, 55000.00, 42000.00, 8, 3),
('Microwave Oven', 4, 12000.00, 9000.00, 20, 8),
('Apple MacBook Pro', 2, 185000.00, 155000.00, 8, 3),
('Wireless Mouse', 2, 1500.00, 800.00, 100, 30);

-- Insert Employees
INSERT INTO employees (name, email, position, hire_date, salary, manager_id) VALUES
('John Smith', 'john.smith@retail.com', 'Store Manager', '2020-01-15', 75000.00, NULL),
('Sarah Johnson', 'sarah.j@retail.com', 'Sales Associate', '2021-03-20', 35000.00, 1),
('Mike Brown', 'mike.b@retail.com', 'Sales Associate', '2021-06-10', 35000.00, 1),
('Emily Davis', 'emily.d@retail.com', 'Inventory Manager', '2020-08-05', 55000.00, 1),
('Robert Wilson', 'robert.w@retail.com', 'Sales Associate', '2022-02-14', 32000.00, 1);

-- Insert Payment Methods
INSERT INTO payment_methods (method_name) VALUES
('Cash'),
('Credit Card'),
('Debit Card'),
('UPI'),
('Net Banking');

-- Insert Customers
INSERT INTO customers (name, email, phone, city, state, tier_id, registration_date, total_spent) VALUES
('Rajesh Kumar', 'rajesh.k@email.com', '9876543210', 'Mumbai', 'Maharashtra', 3, '2023-01-15', 65000.00),
('Priya Sharma', 'priya.s@email.com', '9876543211', 'Delhi', 'Delhi', 2, '2023-02-20', 25000.00),
('Amit Patel', 'amit.p@email.com', '9876543212', 'Ahmedabad', 'Gujarat', 4, '2022-11-10', 125000.00),
('Sneha Reddy', 'sneha.r@email.com', '9876543213', 'Bangalore', 'Karnataka', 2, '2023-03-05', 18000.00),
('Vikram Singh', 'vikram.s@email.com', '9876543214', 'Jaipur', 'Rajasthan', 1, '2023-06-15', 5000.00),
('Anjali Gupta', 'anjali.g@email.com', '9876543215', 'Pune', 'Maharashtra', 3, '2023-04-20', 72000.00),
('Karthik Nair', 'karthik.n@email.com', '9876543216', 'Chennai', 'Tamil Nadu', 2, '2023-05-10', 32000.00),
('Deepika Mehta', 'deepika.m@email.com', '9876543217', 'Kolkata', 'West Bengal', 1, '2023-07-22', 8000.00);

-- Insert Sales
INSERT INTO sales (customer_id, employee_id, sale_date, payment_method_id, subtotal, discount_amount, tax_amount, total_amount, status) VALUES
(1, 2, '2024-01-15 10:30:00', 2, 85000.00, 8500.00, 13770.00, 90270.00, 'completed'),
(2, 3, '2024-01-16 14:20:00', 1, 29000.00, 1450.00, 4959.00, 32509.00, 'completed'),
(3, 2, '2024-01-17 11:00:00', 4, 185000.00, 27750.00, 28305.00, 185555.00, 'completed'),
(4, 4, '2024-01-18 16:45:00', 2, 95000.00, 4750.00, 16245.00, 106495.00, 'completed'),
(1, 5, '2024-01-20 09:15:00', 3, 12000.00, 1200.00, 1944.00, 12744.00, 'completed'),
(5, 2, '2024-01-22 13:30:00', 1, 1500.00, 0.00, 270.00, 1770.00, 'completed'),
(6, 3, '2024-01-25 10:00:00', 4, 120000.00, 12000.00, 19440.00, 127440.00, 'completed'),
(7, 2, '2024-01-28 15:20:00', 2, 65000.00, 3250.00, 11115.00, 72865.00, 'completed'),
(8, 5, '2024-02-01 11:45:00', 1, 55000.00, 0.00, 9900.00, 64900.00, 'completed'),
(3, 2, '2024-02-03 14:30:00', 3, 29000.00, 4350.00, 4437.00, 29087.00, 'completed');

-- Insert Sales Details
INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, discount, line_total) VALUES
(1, 1, 1, 85000.00, 10.00, 76500.00),
(2, 5, 1, 29000.00, 5.00, 27550.00),
(3, 9, 1, 185000.00, 15.00, 157250.00),
(4, 4, 1, 95000.00, 5.00, 90250.00),
(5, 8, 1, 12000.00, 10.00, 10800.00),
(6, 10, 1, 1500.00, 0.00, 1500.00),
(7, 3, 1, 120000.00, 10.00, 108000.00),
(8, 2, 1, 65000.00, 5.00, 61750.00),
(9, 7, 1, 55000.00, 0.00, 55000.00),
(10, 5, 1, 29000.00, 15.00, 24650.00);

-- ================================================================
-- SECTION 3: VIEWS
-- ================================================================

-- View: Sales Summary with Customer and Product Details
CREATE OR REPLACE VIEW vw_sales_summary AS
SELECT 
    s.sale_id,
    s.sale_date,
    c.name AS customer_name,
    c.city,
    c.tier_id,
    ct.tier_name,
    e.name AS employee_name,
    pm.method_name AS payment_method,
    s.total_amount,
    s.status
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
LEFT JOIN employees e ON s.employee_id = e.employee_id
LEFT JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id;

-- View: Product Sales Performance
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.name AS product_name,
    cat.category_name,
    p.price,
    p.stock,
    COUNT(sd.sale_detail_id) AS times_sold,
    SUM(sd.quantity) AS total_quantity_sold,
    SUM(sd.line_total) AS total_revenue,
    AVG(sd.line_total) AS avg_sale_value
FROM products p
LEFT JOIN categories cat ON p.category_id = cat.category_id
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
GROUP BY p.product_id, p.name, cat.category_name, p.price, p.stock;

-- View: Customer Purchase History
CREATE OR REPLACE VIEW vw_customer_analytics AS
SELECT 
    c.customer_id,
    c.name,
    c.email,
    c.city,
    ct.tier_name,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.total_amount) AS lifetime_value,
    AVG(s.total_amount) AS avg_order_value,
    MAX(s.sale_date) AS last_purchase_date,
    DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase
FROM customers c
LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
LEFT JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.name, c.email, c.city, ct.tier_name;

-- ================================================================
-- SECTION 4: WINDOW FUNCTIONS
-- ================================================================

-- Query 1: Rank products by revenue within each category
SELECT 
    category_name,
    product_name,
    total_revenue,
    RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS revenue_rank,
    DENSE_RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS dense_revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS row_num
FROM vw_product_performance
WHERE total_revenue IS NOT NULL
ORDER BY category_name, revenue_rank;

-- Query 2: Calculate running total of sales over time
SELECT 
    sale_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY sale_date) AS running_total,
    AVG(total_amount) OVER (ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_days
FROM sales
ORDER BY sale_date;

-- Query 3: Compare current vs previous sale using LAG function
SELECT 
    sale_id,
    customer_id,
    sale_date,
    total_amount,
    LAG(total_amount, 1) OVER (PARTITION BY customer_id ORDER BY sale_date) AS previous_sale_amount,
    total_amount - LAG(total_amount, 1) OVER (PARTITION BY customer_id ORDER BY sale_date) AS amount_difference,
    LEAD(sale_date, 1) OVER (PARTITION BY customer_id ORDER BY sale_date) AS next_sale_date
FROM sales
ORDER BY customer_id, sale_date;

-- Query 4: Percentile ranking of customers by total spending
SELECT 
    customer_id,
    name,
    lifetime_value,
    PERCENT_RANK() OVER (ORDER BY lifetime_value) AS percentile_rank,
    NTILE(4) OVER (ORDER BY lifetime_value) AS quartile
FROM vw_customer_analytics
WHERE lifetime_value IS NOT NULL
ORDER BY lifetime_value DESC;

-- ================================================================
-- SECTION 5: COMMON TABLE EXPRESSIONS (CTEs)
-- ================================================================

-- Query 5: Find customers who spent more than average using CTE
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.name,
        SUM(s.total_amount) AS total_spent
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.name
),
avg_spending AS (
    SELECT AVG(total_spent) AS avg_amount
    FROM customer_spending
)
SELECT 
    cs.customer_id,
    cs.name,
    cs.total_spent,
    a.avg_amount,
    cs.total_spent - a.avg_amount AS above_average
FROM customer_spending cs
CROSS JOIN avg_spending a
WHERE cs.total_spent > a.avg_amount
ORDER BY cs.total_spent DESC;

-- Query 6: Recursive CTE for Employee Hierarchy
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Top-level managers
    SELECT 
        employee_id,
        name,
        position,
        manager_id,
        1 AS level,
        CAST(name AS CHAR(200)) AS hierarchy_path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Employees reporting to managers
    SELECT 
        e.employee_id,
        e.name,
        e.position,
        e.manager_id,
        eh.level + 1,
        CONCAT(eh.hierarchy_path, ' > ', e.name)
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    CONCAT(REPEAT('  ', level - 1), name) AS employee_name,
    position,
    level,
    hierarchy_path
FROM employee_hierarchy
ORDER BY level, name;

-- Query 7: Monthly sales analysis with CTE
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        COUNT(*) AS total_orders,
        SUM(total_amount) AS monthly_revenue,
        AVG(total_amount) AS avg_order_value
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
)
SELECT 
    month,
    total_orders,
    monthly_revenue,
    avg_order_value,
    LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) / 
           LAG(monthly_revenue) OVER (ORDER BY month) * 100), 2) AS growth_percentage
FROM monthly_sales
ORDER BY month;

-- ================================================================
-- SECTION 6: COMPLEX JOINS AND SUBQUERIES
-- ================================================================

-- Query 8: Self-join to find customers from the same city
SELECT 
    c1.name AS customer1,
    c2.name AS customer2,
    c1.city
FROM customers c1
JOIN customers c2 ON c1.city = c2.city AND c1.customer_id < c2.customer_id
ORDER BY c1.city, c1.name;

-- Query 9: Find products that have never been sold (LEFT JOIN with IS NULL)
SELECT 
    p.product_id,
    p.name,
    p.price,
    p.stock,
    c.category_name
FROM products p
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE sd.product_id IS NULL;

-- Query 10: Correlated subquery - Products priced above category average
SELECT 
    p.product_id,
    p.name,
    c.category_name,
    p.price,
    (SELECT AVG(p2.price) 
     FROM products p2 
     WHERE p2.category_id = p.category_id) AS category_avg_price,
    p.price - (SELECT AVG(p2.price) 
               FROM products p2 
               WHERE p2.category_id = p.category_id) AS price_difference
FROM products p
JOIN categories c ON p.category_id = c.category_id
WHERE p.price > (SELECT AVG(p2.price) 
                 FROM products p2 
                 WHERE p2.category_id = p.category_id)
ORDER BY c.category_name, p.price DESC;

-- Query 11: Find top 3 products in each category by revenue (subquery)
SELECT * FROM (
    SELECT 
        category_name,
        product_name,
        total_revenue,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rn
    FROM vw_product_performance
    WHERE total_revenue IS NOT NULL
) ranked
WHERE rn <= 3
ORDER BY category_name, rn;

-- ================================================================
-- SECTION 7: AGGREGATION WITH GROUPING SETS, ROLLUP, CUBE
-- ================================================================

-- Query 12: Sales summary with ROLLUP (subtotals and grand total)
SELECT 
    COALESCE(c.city, 'All Cities') AS city,
    COALESCE(ct.tier_name, 'All Tiers') AS tier,
    COUNT(s.sale_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN customer_tiers ct ON c.tier_id = ct.tier_id
GROUP BY c.city, ct.tier_name WITH ROLLUP
ORDER BY city, tier;

-- Query 13: Product sales by category and payment method
SELECT 
    COALESCE(cat.category_name, 'All Categories') AS category,
    COALESCE(pm.method_name, 'All Payment Methods') AS payment_method,
    COUNT(DISTINCT s.sale_id) AS num_sales,
    SUM(sd.line_total) AS total_revenue
FROM sales_details sd
JOIN sales s ON sd.sale_id = s.sale_id
JOIN products p ON sd.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id
GROUP BY cat.category_name, pm.method_name WITH ROLLUP;

-- ================================================================
-- SECTION 8: CASE STATEMENTS AND CONDITIONAL LOGIC
-- ================================================================

-- Query 14: Categorize customers based on spending
SELECT 
    customer_id,
    name,
    lifetime_value,
    CASE 
        WHEN lifetime_value >= 100000 THEN 'VIP Customer'
        WHEN lifetime_value >= 50000 THEN 'Premium Customer'
        WHEN lifetime_value >= 20000 THEN 'Regular Customer'
        WHEN lifetime_value > 0 THEN 'New Customer'
        ELSE 'No Purchases'
    END AS customer_segment,
    CASE
        WHEN days_since_last_purchase IS NULL THEN 'Never Purchased'
        WHEN days_since_last_purchase <= 30 THEN 'Active'
        WHEN days_since_last_purchase <= 90 THEN 'At Risk'
        ELSE 'Inactive'
    END AS engagement_status
FROM vw_customer_analytics
ORDER BY lifetime_value DESC;

-- Query 15: Product inventory status with CASE
SELECT 
    p.product_id,
    p.name,
    p.stock,
    p.reorder_level,
    CASE 
        WHEN p.stock = 0 THEN 'Out of Stock'
        WHEN p.stock <= p.reorder_level THEN 'Low Stock - Reorder Needed'
        WHEN p.stock <= p.reorder_level * 2 THEN 'Adequate Stock'
        ELSE 'High Stock'
    END AS inventory_status,
    CASE
        WHEN p.stock < p.reorder_level THEN p.reorder_level * 3 - p.stock
        ELSE 0
    END AS suggested_order_quantity
FROM products p
ORDER BY 
    CASE 
        WHEN p.stock = 0 THEN 1
        WHEN p.stock <= p.reorder_level THEN 2
        ELSE 3
    END,
    p.stock;

-- ================================================================
-- SECTION 9: STRING AND DATE FUNCTIONS
-- ================================================================

-- Query 16: String manipulation examples
SELECT 
    customer_id,
    name,
    UPPER(name) AS uppercase_name,
    LOWER(email) AS lowercase_email,
    CONCAT(name, ' (', city, ', ', state, ')') AS full_location,
    LEFT(email, LOCATE('@', email) - 1) AS email_username,
    SUBSTRING(phone, 1, 3) AS area_code,
    LENGTH(name) AS name_length,
    REPLACE(phone, '987654', 'XXX-XXX') AS masked_phone
FROM customers;

-- Query 17: Date manipulation examples
SELECT 
    sale_id,
    sale_date,
    DATE(sale_date) AS sale_date_only,
    TIME(sale_date) AS sale_time,
    YEAR(sale_date) AS sale_year,
    MONTH(sale_date) AS sale_month,
    DAY(sale_date) AS sale_day,
    DAYNAME(sale_date) AS day_of_week,
    MONTHNAME(sale_date) AS month_name,
    QUARTER(sale_date) AS quarter,
    WEEK(sale_date) AS week_number,
    DATE_ADD(sale_date, INTERVAL 30 DAY) AS warranty_expiry,
    DATEDIFF(CURRENT_DATE, sale_date) AS days_ago
FROM sales
ORDER BY sale_date DESC;

-- ================================================================
-- SECTION 10: STORED PROCEDURES
-- ================================================================

-- Procedure 1: Add new sale with automatic calculations
DELIMITER //
CREATE PROCEDURE sp_add_sale(
    IN p_customer_id INT,
    IN p_employee_id INT,
    IN p_payment_method_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_sale_id INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_discount_pct DECIMAL(5,2);
    DECLARE v_line_total DECIMAL(10,2);
    DECLARE v_tax_rate DECIMAL(5,2) DEFAULT 18.00;
    
    -- Get product price
    SELECT price INTO v_unit_price FROM products WHERE product_id = p_product_id;
    
    -- Get customer discount based on tier
    SELECT discount_percentage INTO v_discount_pct 
    FROM customer_tiers ct
    JOIN customers c ON ct.tier_id = c.tier_id
    WHERE c.customer_id = p_customer_id;
    
    -- Calculate line total
    SET v_line_total = v_unit_price * p_quantity * (1 - v_discount_pct/100);
    
    -- Insert sale header
    INSERT INTO sales (customer_id, employee_id, payment_method_id, subtotal, 
                      discount_amount, tax_amount, total_amount, status)
    VALUES (p_customer_id, p_employee_id, p_payment_method_id,
            v_unit_price * p_quantity,
            (v_unit_price * p_quantity * v_discount_pct / 100),
            (v_line_total * v_tax_rate / 100),
            v_line_total * (1 + v_tax_rate/100),
            'completed');
    
    SET v_sale_id = LAST_INSERT_ID();
    
    -- Insert sale detail
    INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, discount, line_total)
    VALUES (v_sale_id, p_product_id, p_quantity, v_unit_price, v_discount_pct, v_line_total);
    
    -- Update product stock
    UPDATE products 
    SET stock = stock - p_quantity 
    WHERE product_id = p_product_id;
    
    SELECT v_sale_id AS new_sale_id;
END //
DELIMITER ;

-- Procedure 2: Get customer purchase summary
DELIMITER //
CREATE PROCEDURE sp_customer_summary(IN p_customer_id INT)
BEGIN
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        ct.tier_name,
        COUNT(s.sale_id) AS total_orders,
        SUM(s.total_amount) AS total_spent,
        AVG(s.total_amount) AS avg_order_value,
        MIN(s.sale_date) AS first_purchase,
        MAX(s.sale_date) AS last_purchase
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id, c.name, c.email, ct.tier_name;
END //
DELIMITER ;

-- ================================================================
-- SECTION 11: FUNCTIONS
-- ================================================================

-- Function 1: Calculate profit margin for a product
DELIMITER //
CREATE FUNCTION fn_profit_margin(p_product_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_cost DECIMAL(10,2);
    DECLARE v_margin DECIMAL(5,2);
    
    SELECT price, cost_price INTO v_price, v_cost
    FROM products
    WHERE product_id = p_product_id;
    
    IF v_cost > 0 THEN
        SET v_margin = ((v_price - v_cost) / v_price) * 100;
    ELSE
        SET v_margin = 0;
    END IF;
    
    RETURN v_margin;
END //
DELIMITER ;

-- Function 2: Get customer tier name
DELIMITER //
CREATE FUNCTION fn_get_customer_tier(p_total_spent DECIMAL(12,2))
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE v_tier_name VARCHAR(50);
    
    SELECT tier_name INTO v_tier_name
    FROM customer_tiers
    WHERE p_total_spent >= min_purchases
    ORDER BY min_purchases DESC
    LIMIT 1;
    
    RETURN IFNULL(v_tier_name, 'Bronze');
END //
DELIMITER ;

-- ================================================================
-- SECTION 12: TRIGGERS
-- ================================================================

-- Trigger 1: Update customer total_spent after new sale
DELIMITER //
CREATE TRIGGER trg_update_customer_spending
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE customers
    SET total_spent = total_spent + NEW.total_amount,
        last_purchase_date = DATE(NEW.sale_date)
    WHERE customer_id = NEW.customer_id;
END //
DELIMITER ;

-- Trigger 2: Record inventory transaction when sale is made
DELIMITER //
CREATE TRIGGER trg_record_sale_inventory
AFTER INSERT ON sales_details
FOR EACH ROW
BEGIN
    INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes)
    VALUES (NEW.product_id, 'sale', -NEW.quantity, CONCAT('Sale ID: ', NEW.sale_id));
END //
DELIMITER ;

-- Trigger 3: Prevent deletion of products with existing sales
DELIMITER //
CREATE TRIGGER trg_prevent_product_deletion
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count
    FROM sales_details
    WHERE product_id = OLD.product_id;
    
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete product with existing sales records';
    END IF;
END //
DELIMITER ;

-- ================================================================
-- SECTION 13: ADVANCED ANALYTICS QUERIES
-- ================================================================

-- Query 18: RFM Analysis (Recency, Frequency, Monetary)
WITH rfm_calc AS (
    SELECT 
        c.customer_id,
        c.name,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS recency_days,
        COUNT(s.sale_id) AS frequency,
        SUM(s.total_amount) AS monetary
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.name
),
rfm_scores AS (
    SELECT 
        customer_id,
        name,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_calc
)
SELECT 
    customer_id,
    name,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total_score,
    CASE 
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
        ELSE 'Potential'
    END AS customer_segment
FROM rfm_scores
ORDER BY rfm_total_score DESC;

-- Query 19: Cohort Analysis - Customer retention by registration month
WITH cohort_data AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(c.registration_date, '%Y-%m') AS cohort_month,
        DATE_FORMAT(s.sale_date, '%Y-%m') AS purchase_month,
        PERIOD_DIFF(
            DATE_FORMAT(s.sale_date, '%Y%m'),
            DATE_FORMAT(c.registration_date, '%Y%m')
        ) AS months_since_registration
    FROM customers c
    LEFT JOIN sales s ON c.customer_id = s.customer_id
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN months_since_registration = 1 THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN months_since_registration = 2 THEN customer_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN months_since_registration = 3 THEN customer_id END) AS month_3
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month;

-- Query 20: Product affinity analysis (products often bought together)
SELECT 
    p1.name AS product_1,
    p2.name AS product_2,
    COUNT(*) AS times_bought_together
FROM sales_details sd1
JOIN sales_details sd2 ON sd1.sale_id = sd2.sale_id AND sd1.product_id < sd2.product_id
JOIN products p1 ON sd1.product_id = p1.product_id
JOIN products p2 ON sd2.product_id = p2.product_id
GROUP BY p1.product_id, p1.name, p2.product_id, p2.name
HAVING COUNT(*) >= 1
ORDER BY times_bought_together DESC;

-- Query 21: Sales forecasting using moving averages
WITH daily_sales AS (
    SELECT 
        DATE(sale_date) AS sale_date,
        SUM(total_amount) AS daily_total
    FROM sales
    WHERE status = 'completed'
    GROUP BY DATE(sale_date)
)
SELECT 
    sale_date,
    daily_total,
    AVG(daily_total) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ma_7_day,
    AVG(daily_total) OVER (ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS ma_30_day
FROM daily_sales
ORDER BY sale_date;

-- Query 22: Employee performance analysis
SELECT 
    e.employee_id,
    e.name,
    e.position,
    COUNT(s.sale_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_sale_value,
    RANK() OVER (ORDER BY SUM(s.total_amount) DESC) AS revenue_rank
FROM employees e
LEFT JOIN sales s ON e.employee_id = s.employee_id
GROUP BY e.employee_id, e.name, e.position
ORDER BY total_revenue DESC;

-- ================================================================
-- SECTION 14: INDEXES AND OPTIMIZATION
-- ================================================================

-- Show existing indexes
SHOW INDEX FROM sales;
SHOW INDEX FROM products;

-- Analyze query execution plan
EXPLAIN SELECT 
    c.name, s.sale_date, s.total_amount
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.sale_date >= '2024-01-01'
ORDER BY s.sale_date DESC;

-- Create composite index for better performance
CREATE INDEX idx_sale_date_customer ON sales(sale_date, customer_id);

-- Full-text search index example
ALTER TABLE products ADD FULLTEXT INDEX ft_product_name (name);

-- Query using full-text search
SELECT product_id, name, price
FROM products
WHERE MATCH(name) AGAINST('laptop' IN NATURAL LANGUAGE MODE);

-- ================================================================
-- END OF ADVANCED SQL QUERIES
-- ================================================================
