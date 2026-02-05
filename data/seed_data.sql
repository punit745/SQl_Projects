-- ================================================================
-- SEED DATA SCRIPT
-- Core sample data for the retail sales database
-- Run after: All schema creation scripts
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: LOOKUP/REFERENCE DATA
-- ================================================================

-- Customer Tiers
INSERT INTO customer_tiers (tier_name, min_purchases, discount_percentage, benefits) VALUES
('Bronze', 0, 0, 'Basic member benefits'),
('Silver', 10000, 5, '5% discount on all purchases'),
('Gold', 50000, 10, '10% discount + free shipping'),
('Platinum', 100000, 15, '15% discount + priority support + exclusive offers');

-- Categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Computers', 'Laptops, desktops, and computer accessories'),
('Mobile Phones', 'Smartphones and mobile accessories'),
('Home Appliances', 'Kitchen and home appliances'),
('Audio & Video', 'Headphones, speakers, and entertainment systems');

-- Payment Methods
INSERT INTO payment_methods (method_name, processing_fee_percentage, is_active) VALUES
('Cash', 0, TRUE),
('Credit Card', 2.5, TRUE),
('Debit Card', 1.5, TRUE),
('UPI', 0, TRUE),
('Net Banking', 1.0, TRUE);

-- ================================================================
-- SECTION 2: EMPLOYEES
-- ================================================================

INSERT INTO employees (name, email, phone, position, department, hire_date, salary, commission_rate, manager_id) VALUES
('John Smith', 'john.smith@retail.com', '9876543200', 'Store Manager', 'Management', '2020-01-15', 75000.00, 0, NULL),
('Sarah Johnson', 'sarah.j@retail.com', '9876543201', 'Senior Sales Associate', 'Sales', '2021-03-20', 40000.00, 2.0, 1),
('Mike Brown', 'mike.b@retail.com', '9876543202', 'Sales Associate', 'Sales', '2021-06-10', 35000.00, 1.5, 1),
('Emily Davis', 'emily.d@retail.com', '9876543203', 'Inventory Manager', 'Operations', '2020-08-05', 55000.00, 0, 1),
('Robert Wilson', 'robert.w@retail.com', '9876543204', 'Sales Associate', 'Sales', '2022-02-14', 32000.00, 1.5, 2);

-- ================================================================
-- SECTION 3: PRODUCTS
-- ================================================================

INSERT INTO products (name, sku, category_id, price, cost_price, stock, reorder_level, description) VALUES
('Dell Latitude Laptop', 'SKU-001001', 2, 85000.00, 70000.00, 15, 5, 'Business laptop with Intel Core i5'),
('HP Desktop PC', 'SKU-001002', 2, 65000.00, 52000.00, 10, 5, 'Complete desktop solution for home and office'),
('iPhone 14 Pro', 'SKU-002001', 3, 120000.00, 100000.00, 25, 10, 'Latest Apple smartphone with advanced features'),
('Samsung Galaxy S23', 'SKU-002002', 3, 95000.00, 78000.00, 30, 10, 'Premium Android smartphone'),
('Sony Headphones WH-1000XM5', 'SKU-003001', 5, 29000.00, 22000.00, 40, 15, 'Industry-leading noise cancellation headphones'),
('LG 65" 4K TV', 'SKU-003002', 5, 85000.00, 68000.00, 12, 5, 'Ultra HD smart TV with webOS'),
('Samsung Refrigerator', 'SKU-004001', 4, 55000.00, 42000.00, 8, 3, 'Double door frost-free refrigerator'),
('Microwave Oven', 'SKU-004002', 4, 12000.00, 9000.00, 20, 8, 'Convection microwave oven'),
('Apple MacBook Pro', 'SKU-001003', 2, 185000.00, 155000.00, 8, 3, 'M2 Pro chip, 14-inch display'),
('Wireless Mouse', 'SKU-001004', 2, 1500.00, 800.00, 100, 30, 'Ergonomic wireless mouse');

-- ================================================================
-- SECTION 4: CUSTOMERS
-- ================================================================

INSERT INTO customers (name, email, phone, address, city, state, zip_code, tier_id, registration_date, total_spent, preferences) VALUES
('Rajesh Kumar', 'rajesh.k@email.com', '9876543210', '123 Marine Drive', 'Mumbai', 'Maharashtra', '400001', 3, '2023-01-15', 65000.00, 
 '{"newsletter": true, "preferred_categories": [1, 2]}'),
('Priya Sharma', 'priya.s@email.com', '9876543211', '456 Connaught Place', 'Delhi', 'Delhi', '110001', 2, '2023-02-20', 25000.00,
 '{"newsletter": true, "preferred_categories": [3, 4]}'),
('Amit Patel', 'amit.p@email.com', '9876543212', '789 CG Road', 'Ahmedabad', 'Gujarat', '380009', 4, '2022-11-10', 125000.00,
 '{"newsletter": true, "preferred_categories": [1, 2, 3]}'),
('Sneha Reddy', 'sneha.r@email.com', '9876543213', '101 MG Road', 'Bangalore', 'Karnataka', '560001', 2, '2023-03-05', 18000.00,
 '{"newsletter": false, "preferred_categories": [5]}'),
('Vikram Singh', 'vikram.s@email.com', '9876543214', '202 MI Road', 'Jaipur', 'Rajasthan', '302001', 1, '2023-06-15', 5000.00,
 '{"newsletter": true}'),
('Anjali Gupta', 'anjali.g@email.com', '9876543215', '303 Fergusson Road', 'Pune', 'Maharashtra', '411001', 3, '2023-04-20', 72000.00,
 '{"newsletter": true, "preferred_categories": [2, 3]}'),
('Karthik Nair', 'karthik.n@email.com', '9876543216', '404 Anna Salai', 'Chennai', 'Tamil Nadu', '600002', 2, '2023-05-10', 32000.00,
 '{"newsletter": false, "preferred_categories": [1]}'),
('Deepika Mehta', 'deepika.m@email.com', '9876543217', '505 Park Street', 'Kolkata', 'West Bengal', '700016', 1, '2023-07-22', 8000.00,
 '{"newsletter": true}');

-- ================================================================
-- SECTION 5: SAMPLE SALES
-- ================================================================

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

-- ================================================================
-- SECTION 6: SAMPLE SALES DETAILS
-- ================================================================

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
-- SECTION 7: SAMPLE INVENTORY TRANSACTIONS
-- ================================================================

INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes, created_by) VALUES
(1, 'purchase', 20, 'Initial stock purchase', 4),
(2, 'purchase', 15, 'Initial stock purchase', 4),
(3, 'purchase', 30, 'Initial stock purchase', 4),
(4, 'purchase', 35, 'Initial stock purchase', 4),
(5, 'purchase', 50, 'Initial stock purchase', 4),
(1, 'sale', -1, 'Sale ID: 1', NULL),
(5, 'sale', -1, 'Sale ID: 2', NULL),
(9, 'sale', -1, 'Sale ID: 3', NULL);

-- ================================================================
-- SECTION 8: VERIFY DATA
-- ================================================================

SELECT 'Seed Data Summary' AS report;

SELECT 
    'customer_tiers' AS table_name, COUNT(*) AS record_count FROM customer_tiers
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'payment_methods', COUNT(*) FROM payment_methods
UNION ALL SELECT 'employees', COUNT(*) FROM employees
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'sales_details', COUNT(*) FROM sales_details
UNION ALL SELECT 'inventory_transactions', COUNT(*) FROM inventory_transactions;

SELECT 'Seed data loaded successfully!' AS status;

-- ================================================================
-- END OF SEED DATA
-- ================================================================
