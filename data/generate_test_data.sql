-- ================================================================
-- TEST DATA GENERATION SCRIPT
-- Generate large datasets for performance testing
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: CONFIGURATION
-- ================================================================

-- Set these variables to control data generation
SET @num_customers = 1000;
SET @num_products = 100;
SET @num_sales = 5000;
SET @start_date = '2023-01-01';
SET @end_date = '2024-12-31';

-- ================================================================
-- SECTION 2: HELPER PROCEDURES FOR DATA GENERATION
-- ================================================================

-- Generate random customers
DELIMITER //
CREATE PROCEDURE sp_generate_customers(IN p_count INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_first_names JSON;
    DECLARE v_last_names JSON;
    DECLARE v_cities JSON;
    DECLARE v_states JSON;
    DECLARE v_first_name VARCHAR(50);
    DECLARE v_last_name VARCHAR(50);
    
    SET v_first_names = '["Rajesh", "Priya", "Amit", "Sneha", "Vikram", "Anjali", "Karthik", "Deepika", "Rahul", "Pooja", "Suresh", "Meera", "Arun", "Kavitha", "Mohan", "Lakshmi", "Vijay", "Sunita", "Ravi", "Geeta"]';
    SET v_last_names = '["Kumar", "Sharma", "Patel", "Reddy", "Singh", "Gupta", "Nair", "Mehta", "Verma", "Iyer", "Joshi", "Shah", "Rao", "Malhotra", "Kapoor", "Das", "Pillai", "Bose", "Chatterjee", "Mukherjee"]';
    SET v_cities = '["Mumbai", "Delhi", "Bangalore", "Chennai", "Kolkata", "Hyderabad", "Pune", "Ahmedabad", "Jaipur", "Lucknow", "Surat", "Nagpur", "Indore", "Bhopal", "Chandigarh"]';
    SET v_states = '["Maharashtra", "Delhi", "Karnataka", "Tamil Nadu", "West Bengal", "Telangana", "Maharashtra", "Gujarat", "Rajasthan", "Uttar Pradesh", "Gujarat", "Maharashtra", "Madhya Pradesh", "Madhya Pradesh", "Punjab"]';
    
    WHILE i < p_count DO
        SET v_first_name = JSON_UNQUOTE(JSON_EXTRACT(v_first_names, CONCAT('$[', FLOOR(RAND() * 20), ']')));
        SET v_last_name = JSON_UNQUOTE(JSON_EXTRACT(v_last_names, CONCAT('$[', FLOOR(RAND() * 20), ']')));
        
        INSERT IGNORE INTO customers (
            name, 
            email, 
            phone, 
            city, 
            state, 
            tier_id, 
            registration_date
        )
        VALUES (
            CONCAT(v_first_name, ' ', v_last_name),
            LOWER(CONCAT(v_first_name, '.', v_last_name, i, '@example.com')),
            CONCAT('9', LPAD(FLOOR(RAND() * 1000000000), 9, '0')),
            JSON_UNQUOTE(JSON_EXTRACT(v_cities, CONCAT('$[', FLOOR(RAND() * 15), ']'))),
            JSON_UNQUOTE(JSON_EXTRACT(v_states, CONCAT('$[', FLOOR(RAND() * 15), ']'))),
            1 + FLOOR(RAND() * 4),
            DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 730) DAY)
        );
        
        SET i = i + 1;
    END WHILE;
    
    SELECT CONCAT(p_count, ' customers generated') AS status;
END //
DELIMITER ;

-- Generate random products
DELIMITER //
CREATE PROCEDURE sp_generate_products(IN p_count INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_product_types JSON;
    DECLARE v_adjectives JSON;
    DECLARE v_type VARCHAR(50);
    DECLARE v_adj VARCHAR(50);
    DECLARE v_price DECIMAL(10,2);
    
    SET v_product_types = '["Laptop", "Desktop", "Monitor", "Keyboard", "Mouse", "Headphones", "Webcam", "Printer", "Scanner", "Router", "USB Drive", "External HDD", "SSD", "RAM Module", "Graphics Card", "Processor", "Motherboard", "Power Supply", "Cabinet", "Cooling Fan"]';
    SET v_adjectives = '["Pro", "Ultra", "Max", "Elite", "Prime", "Plus", "Advanced", "Premium", "Standard", "Basic", "Lite", "Mini", "Compact", "Slim", "Wireless", "Gaming", "Professional", "Home", "Office", "Enterprise"]';
    
    WHILE i < p_count DO
        SET v_type = JSON_UNQUOTE(JSON_EXTRACT(v_product_types, CONCAT('$[', FLOOR(RAND() * 20), ']')));
        SET v_adj = JSON_UNQUOTE(JSON_EXTRACT(v_adjectives, CONCAT('$[', FLOOR(RAND() * 20), ']')));
        SET v_price = 1000 + FLOOR(RAND() * 199000);
        
        INSERT IGNORE INTO products (
            name,
            sku,
            category_id,
            price,
            cost_price,
            stock,
            reorder_level
        )
        VALUES (
            CONCAT(v_adj, ' ', v_type, ' ', i),
            CONCAT('SKU-', LPAD(i, 6, '0')),
            1 + FLOOR(RAND() * 5),
            v_price,
            v_price * (0.5 + RAND() * 0.3),
            FLOOR(RAND() * 100),
            5 + FLOOR(RAND() * 15)
        );
        
        SET i = i + 1;
    END WHILE;
    
    SELECT CONCAT(p_count, ' products generated') AS status;
END //
DELIMITER ;

-- Generate random sales
DELIMITER //
CREATE PROCEDURE sp_generate_sales(
    IN p_count INT,
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_customer_id INT;
    DECLARE v_employee_id INT;
    DECLARE v_product_id INT;
    DECLARE v_sale_date DATETIME;
    DECLARE v_quantity INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_discount DECIMAL(10,2);
    DECLARE v_tax DECIMAL(10,2);
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_sale_id INT;
    DECLARE v_date_range INT;
    DECLARE v_max_customer INT;
    DECLARE v_max_product INT;
    DECLARE v_max_employee INT;
    
    -- Get max IDs
    SELECT MAX(customer_id) INTO v_max_customer FROM customers;
    SELECT MAX(product_id) INTO v_max_product FROM products;
    SELECT MAX(employee_id) INTO v_max_employee FROM employees;
    
    SET v_date_range = DATEDIFF(p_end_date, p_start_date);
    
    -- Disable triggers temporarily for bulk insert performance
    SET @TRIGGER_DISABLED = TRUE;
    
    WHILE i < p_count DO
        -- Random values
        SET v_customer_id = 1 + FLOOR(RAND() * v_max_customer);
        SET v_employee_id = 1 + FLOOR(RAND() * v_max_employee);
        SET v_product_id = 1 + FLOOR(RAND() * v_max_product);
        SET v_sale_date = DATE_ADD(p_start_date, INTERVAL FLOOR(RAND() * v_date_range) DAY);
        SET v_sale_date = DATE_ADD(v_sale_date, INTERVAL FLOOR(RAND() * 86400) SECOND);
        SET v_quantity = 1 + FLOOR(RAND() * 5);
        
        -- Get product price
        SELECT COALESCE(price, 10000) INTO v_price FROM products WHERE product_id = v_product_id LIMIT 1;
        
        -- Calculate amounts
        SET v_subtotal = v_price * v_quantity;
        SET v_discount = v_subtotal * (RAND() * 0.15);
        SET v_tax = (v_subtotal - v_discount) * 0.18;
        SET v_total = v_subtotal - v_discount + v_tax;
        
        -- Insert sale
        INSERT INTO sales (
            customer_id, employee_id, sale_date, payment_method_id,
            subtotal, discount_amount, tax_amount, total_amount, status
        )
        VALUES (
            v_customer_id, v_employee_id, v_sale_date, 1 + FLOOR(RAND() * 5),
            v_subtotal, v_discount, v_tax, v_total, 'completed'
        );
        
        SET v_sale_id = LAST_INSERT_ID();
        
        -- Insert sale detail
        INSERT INTO sales_details (
            sale_id, product_id, quantity, unit_price, discount, line_total
        )
        VALUES (
            v_sale_id, v_product_id, v_quantity, v_price, 
            v_discount / v_subtotal * 100, v_subtotal - v_discount
        );
        
        SET i = i + 1;
        
        -- Progress indicator every 500 records
        IF i MOD 500 = 0 THEN
            SELECT CONCAT(i, ' sales generated...') AS progress;
        END IF;
    END WHILE;
    
    SET @TRIGGER_DISABLED = FALSE;
    
    SELECT CONCAT(p_count, ' sales generated') AS status;
END //
DELIMITER ;

-- ================================================================
-- SECTION 3: MASTER DATA GENERATION PROCEDURE
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_generate_all_test_data(
    IN p_customers INT,
    IN p_products INT,
    IN p_sales INT
)
BEGIN
    DECLARE v_start_time DATETIME;
    DECLARE v_end_time DATETIME;
    
    SET v_start_time = NOW();
    
    SELECT 'Starting data generation...' AS status;
    
    -- Generate customers
    CALL sp_generate_customers(p_customers);
    
    -- Generate products
    CALL sp_generate_products(p_products);
    
    -- Generate sales
    CALL sp_generate_sales(p_sales, '2023-01-01', '2024-12-31');
    
    SET v_end_time = NOW();
    
    SELECT 
        'Data generation complete!' AS status,
        TIMESTAMPDIFF(SECOND, v_start_time, v_end_time) AS duration_seconds,
        (SELECT COUNT(*) FROM customers) AS total_customers,
        (SELECT COUNT(*) FROM products) AS total_products,
        (SELECT COUNT(*) FROM sales) AS total_sales;
END //
DELIMITER ;

-- ================================================================
-- SECTION 4: QUICK DATA GENERATION
-- ================================================================

-- Generate small dataset (for quick testing)
-- CALL sp_generate_all_test_data(100, 50, 500);

-- Generate medium dataset
-- CALL sp_generate_all_test_data(500, 100, 2000);

-- Generate large dataset (for performance testing)
-- CALL sp_generate_all_test_data(2000, 200, 10000);

-- ================================================================
-- SECTION 5: DATA CLEANUP
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_cleanup_test_data()
BEGIN
    SET FOREIGN_KEY_CHECKS = 0;
    
    TRUNCATE TABLE audit_log;
    TRUNCATE TABLE inventory_transactions;
    TRUNCATE TABLE sales_details;
    TRUNCATE TABLE sales;
    DELETE FROM customers WHERE customer_id > 8;  -- Keep original sample data
    DELETE FROM products WHERE product_id > 10;   -- Keep original sample data
    
    SET FOREIGN_KEY_CHECKS = 1;
    
    SELECT 'Test data cleaned up. Sample data retained.' AS status;
END //
DELIMITER ;

-- ================================================================
-- SECTION 6: USAGE EXAMPLES
-- ================================================================

/*
-- Generate 100 test customers
CALL sp_generate_customers(100);

-- Generate 50 test products  
CALL sp_generate_products(50);

-- Generate 500 test sales for 2024
CALL sp_generate_sales(500, '2024-01-01', '2024-12-31');

-- Generate all test data at once
CALL sp_generate_all_test_data(500, 100, 2000);

-- Clean up test data
CALL sp_cleanup_test_data();
*/

-- ================================================================
-- END OF TEST DATA GENERATION
-- ================================================================
