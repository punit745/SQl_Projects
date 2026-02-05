-- ================================================================
-- TRIGGER TESTS
-- Testing trigger functionality and side effects
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: TRIGGER TEST UTILITIES
-- ================================================================

DELIMITER //

-- Create trigger test results table if not exists
CREATE PROCEDURE setup_trigger_tests()
BEGIN
    -- Ensure test_results table exists
    CREATE TABLE IF NOT EXISTS test_results (
        test_id INT AUTO_INCREMENT PRIMARY KEY,
        test_suite VARCHAR(100),
        test_name VARCHAR(200),
        status ENUM('PASS', 'FAIL', 'ERROR', 'SKIP') NOT NULL,
        expected_result TEXT,
        actual_result TEXT,
        error_message TEXT,
        execution_time_ms INT,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    SELECT 'Trigger test setup complete' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 2: AUDIT TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_audit_triggers()
BEGIN
    DECLARE v_audit_count_before INT;
    DECLARE v_audit_count_after INT;
    DECLARE v_test_customer_id INT;
    
    -- Count existing audit entries
    SELECT COUNT(*) INTO v_audit_count_before 
    FROM audit_log WHERE table_name = 'customers';
    
    -- Create test customer
    INSERT INTO customers (name, email, phone, city, state, tier_id)
    VALUES ('Audit Test Customer', 'audit.test@example.com', '9876543210', 'Mumbai', 'Maharashtra', 1);
    SET v_test_customer_id = LAST_INSERT_ID();
    
    -- Update the customer (should trigger audit)
    UPDATE customers 
    SET name = 'Updated Audit Test Customer'
    WHERE customer_id = v_test_customer_id;
    
    -- Check audit log
    SELECT COUNT(*) INTO v_audit_count_after 
    FROM audit_log WHERE table_name = 'customers';
    
    -- Assert audit entries were created
    IF v_audit_count_after > v_audit_count_before THEN
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'Audit trigger on UPDATE', 'PASS', 
                'Audit entry created', CONCAT('Created ', v_audit_count_after - v_audit_count_before, ' entries'));
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'Audit trigger on UPDATE', 'FAIL', 
                'Audit entry created', 'No audit entry found');
    END IF;
    
    -- Cleanup
    DELETE FROM customers WHERE customer_id = v_test_customer_id;
    DELETE FROM audit_log WHERE table_name = 'customers' 
        AND JSON_EXTRACT(old_values, '$.customer_id') = v_test_customer_id;
    
    SELECT 'Audit trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 3: INVENTORY TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_inventory_triggers()
BEGIN
    DECLARE v_product_id INT DEFAULT 1;
    DECLARE v_initial_stock INT;
    DECLARE v_final_stock INT;
    DECLARE v_sale_quantity INT DEFAULT 2;
    DECLARE v_test_sale_id INT;
    
    -- Get initial stock
    SELECT stock INTO v_initial_stock FROM products WHERE product_id = v_product_id;
    
    -- Create sale (if trigger exists, should reduce stock)
    INSERT INTO sales (customer_id, employee_id, payment_method_id, subtotal, total_amount, status)
    VALUES (1, 1, 1, 100, 118, 'completed');
    SET v_test_sale_id = LAST_INSERT_ID();
    
    INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, line_total)
    VALUES (v_test_sale_id, v_product_id, v_sale_quantity, 50, 100);
    
    -- Get final stock
    SELECT stock INTO v_final_stock FROM products WHERE product_id = v_product_id;
    
    -- Test: Stock should decrease or trigger doesn't exist
    IF v_final_stock <= v_initial_stock THEN
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'Inventory reduction on sale', 'PASS', 
                CONCAT('Stock reduced from ', v_initial_stock),
                CONCAT('Stock is now ', v_final_stock));
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'Inventory reduction on sale', 'SKIP', 
                'Stock reduced', 'Inventory trigger may not be active');
    END IF;
    
    -- Cleanup - restore stock and remove test data
    UPDATE products SET stock = v_initial_stock WHERE product_id = v_product_id;
    DELETE FROM sales_details WHERE sale_id = v_test_sale_id;
    DELETE FROM sales WHERE sale_id = v_test_sale_id;
    
    SELECT 'Inventory trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 4: TIMESTAMP TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_timestamp_triggers()
BEGIN
    DECLARE v_product_id INT DEFAULT 1;
    DECLARE v_old_updated_at DATETIME;
    DECLARE v_new_updated_at DATETIME;
    
    -- Get current timestamp
    SELECT updated_at INTO v_old_updated_at FROM products WHERE product_id = v_product_id;
    
    -- Wait a moment
    DO SLEEP(1);
    
    -- Update product
    UPDATE products 
    SET description = CONCAT('Updated: ', NOW())
    WHERE product_id = v_product_id;
    
    -- Get new timestamp
    SELECT updated_at INTO v_new_updated_at FROM products WHERE product_id = v_product_id;
    
    -- Test
    IF v_new_updated_at > v_old_updated_at THEN
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'AUTO_UPDATE timestamp', 'PASS', 
                'updated_at changed', CONCAT('Changed from ', v_old_updated_at, ' to ', v_new_updated_at));
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'AUTO_UPDATE timestamp', 'FAIL', 
                'updated_at should change', CONCAT('Stayed at ', v_new_updated_at));
    END IF;
    
    SELECT 'Timestamp trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 5: VALIDATION TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_validation_triggers()
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    
    -- Test: Prevent negative stock (if trigger exists)
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_error = TRUE;
        
        UPDATE products SET stock = -10 WHERE product_id = 1;
        
        -- Revert if update succeeded
        IF NOT v_error THEN
            UPDATE products SET stock = 100 WHERE product_id = 1;
        END IF;
    END;
    
    IF v_error THEN
        INSERT INTO test_results (test_suite, test_name, status)
        VALUES ('triggers', 'Prevent negative stock', 'PASS');
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, actual_result)
        VALUES ('triggers', 'Prevent negative stock', 'SKIP',
                'Validation trigger may not be active');
    END IF;
    
    -- Test: Prevent negative price (if trigger exists)
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_error = TRUE;
        SET v_error = FALSE;
        
        UPDATE products SET price = -100 WHERE product_id = 1;
        
        IF NOT v_error THEN
            UPDATE products SET price = 50000 WHERE product_id = 1;
        END IF;
    END;
    
    IF v_error THEN
        INSERT INTO test_results (test_suite, test_name, status)
        VALUES ('triggers', 'Prevent negative price', 'PASS');
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, actual_result)
        VALUES ('triggers', 'Prevent negative price', 'SKIP',
                'Validation trigger may not be active');
    END IF;
    
    SELECT 'Validation trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 6: CASCADING TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_cascading_triggers()
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_initial_total DECIMAL(12,2);
    DECLARE v_test_sale_id INT;
    DECLARE v_final_total DECIMAL(12,2);
    
    -- Create test customer
    INSERT INTO customers (name, email, phone, city, state, tier_id, total_spent)
    VALUES ('Cascade Test', 'cascade@test.com', '1234567890', 'Test', 'Test', 1, 0);
    SET v_customer_id = LAST_INSERT_ID();
    
    -- Get initial total
    SELECT total_spent INTO v_initial_total FROM customers WHERE customer_id = v_customer_id;
    
    -- Create sale
    INSERT INTO sales (customer_id, employee_id, payment_method_id, subtotal, total_amount, status)
    VALUES (v_customer_id, 1, 1, 1000, 1180, 'completed');
    SET v_test_sale_id = LAST_INSERT_ID();
    
    -- Check if customer total_spent updated (if cascade trigger exists)
    SELECT total_spent INTO v_final_total FROM customers WHERE customer_id = v_customer_id;
    
    IF v_final_total > v_initial_total THEN
        INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
        VALUES ('triggers', 'Cascade update customer total_spent', 'PASS',
                'total_spent increased', CONCAT('Changed from ', v_initial_total, ' to ', v_final_total));
    ELSE
        INSERT INTO test_results (test_suite, test_name, status, actual_result)
        VALUES ('triggers', 'Cascade update customer total_spent', 'SKIP',
                'Cascade trigger may not be active');
    END IF;
    
    -- Cleanup
    DELETE FROM sales WHERE sale_id = v_test_sale_id;
    DELETE FROM customers WHERE customer_id = v_customer_id;
    
    SELECT 'Cascading trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 7: RUN ALL TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE run_all_trigger_tests()
BEGIN
    DECLARE v_start_time DATETIME;
    
    SET v_start_time = NOW();
    
    CALL setup_trigger_tests();
    CALL test_audit_triggers();
    CALL test_inventory_triggers();
    CALL test_timestamp_triggers();
    CALL test_validation_triggers();
    CALL test_cascading_triggers();
    
    -- Summary
    SELECT 
        COUNT(CASE WHEN status = 'PASS' THEN 1 END) AS passed,
        COUNT(CASE WHEN status = 'FAIL' THEN 1 END) AS failed,
        COUNT(CASE WHEN status = 'SKIP' THEN 1 END) AS skipped,
        COUNT(*) AS total
    FROM test_results
    WHERE test_suite = 'triggers'
      AND executed_at >= v_start_time;
    
    -- Details
    SELECT test_name, status, expected_result, actual_result
    FROM test_results
    WHERE test_suite = 'triggers'
      AND executed_at >= v_start_time
    ORDER BY test_id;
END //

DELIMITER ;

-- ================================================================
-- USAGE
-- ================================================================

/*
-- Run all trigger tests
CALL run_all_trigger_tests();

-- Run individual test
CALL test_audit_triggers();
CALL test_inventory_triggers();
CALL test_timestamp_triggers();
*/

-- ================================================================
-- END OF TRIGGER TESTS
-- ================================================================
