-- ================================================================
-- BASIC RETAIL SALES DATABASE - SIMPLE SCHEMA
-- This is a simplified version for learning SQL basics
-- For advanced features, see Advanced_SQL_Queries.sql
-- ================================================================

-- Create database
CREATE DATABASE retail_sales_2;
USE retail_sales_2;

-- Products Table
-- Stores product information including price and inventory
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock INT DEFAULT 0,
    INDEX idx_name (name)
);

-- Customers Table
-- Stores customer contact information
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    INDEX idx_email (email)
);

-- Sales Table
-- Stores sales transaction headers
CREATE TABLE sales (
    sale_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_customer (customer_id),
    INDEX idx_date (sale_date)
);

-- Sales Details Table
-- Stores individual line items for each sale
CREATE TABLE sales_details (
    sale_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (sale_id) REFERENCES sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_sale (sale_id),
    INDEX idx_product (product_id)
);

-- ================================================================
-- SAMPLE DATA
-- ================================================================

-- Insert sample products
INSERT INTO products (name, price, stock) VALUES
('Laptop', 85000.00, 10),
('Smartphone', 30000.00, 20),
('Tablet', 25000.00, 15),
('Headphones', 5000.00, 50),
('Mouse', 1000.00, 100);

-- Insert sample customers
INSERT INTO customers (name, email) VALUES
('John Doe', 'john@email.com'),
('Jane Smith', 'jane@email.com'),
('Bob Johnson', 'bob@email.com');

-- Insert sample sales
INSERT INTO sales (customer_id, sale_date) VALUES
(1, '2024-01-15'),
(2, '2024-01-16'),
(1, '2024-01-20');

-- Insert sample sales details
INSERT INTO sales_details (sale_id, product_id, quantity) VALUES
(1, 1, 1),  -- John bought 1 Laptop
(1, 4, 1),  -- John bought 1 Headphones
(2, 2, 2),  -- Jane bought 2 Smartphones
(3, 5, 5);  -- John bought 5 Mice

-- ================================================================
-- BASIC QUERIES FOR LEARNING
-- ================================================================

-- Query 1: View all products
SELECT * FROM products;

-- Query 2: View all customers
SELECT * FROM customers;

-- Query 3: View all sales with customer information
SELECT 
    s.sale_id,
    c.name AS customer_name,
    s.sale_date
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id;

-- Query 4: View detailed sales information
SELECT 
    s.sale_id,
    c.name AS customer_name,
    s.sale_date,
    p.name AS product_name,
    sd.quantity,
    p.price,
    (sd.quantity * p.price) AS line_total
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN sales_details sd ON s.sale_id = sd.sale_id
JOIN products p ON sd.product_id = p.product_id
ORDER BY s.sale_date DESC;

-- Query 5: Total sales by customer
SELECT 
    c.name AS customer_name,
    COUNT(s.sale_id) AS number_of_orders,
    SUM(sd.quantity * p.price) AS total_spent
FROM customers c
LEFT JOIN sales s ON c.customer_id = s.customer_id
LEFT JOIN sales_details sd ON s.sale_id = sd.sale_id
LEFT JOIN products p ON sd.product_id = p.product_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- ================================================================
-- NOTE: For advanced SQL features including:
-- - Window Functions
-- - CTEs (Common Table Expressions)
-- - Stored Procedures
-- - Triggers
-- - And much more...
-- 
-- Please refer to: Advanced_SQL_Queries.sql
-- ================================================================

