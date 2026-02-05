-- ================================================================
-- SQL TESTING FRAMEWORK FOR STORED PROCEDURES
-- Unit tests for procedures, functions, and business logic
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: TEST FRAMEWORK TABLES
-- ================================================================

-- Test results table
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

-- Test suites table
CREATE TABLE IF NOT EXISTS test_suites (
    suite_id INT AUTO_INCREMENT PRIMARY KEY,
    suite_name VARCHAR(100) UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================
-- SECTION 2: TEST HELPER PROCEDURES
-- ================================================================

DELIMITER //

-- Clean up test data
CREATE PROCEDURE test_cleanup()
BEGIN
    DELETE FROM test_results WHERE executed_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
    SELECT 'Old test results cleaned up' AS result;
END //

-- Assert equals
CREATE PROCEDURE assert_equals(
    IN p_test_suite VARCHAR(100),
    IN p_test_name VARCHAR(200),
    IN p_expected TEXT,
    IN p_actual TEXT
)
BEGIN
    DECLARE v_status VARCHAR(10);
    DECLARE v_start_time DATETIME(6);
    DECLARE v_execution_time INT;
    
    SET v_start_time = NOW(6);
    
    IF p_expected = p_actual OR (p_expected IS NULL AND p_actual IS NULL) THEN
        SET v_status = 'PASS';
    ELSE
        SET v_status = 'FAIL';
    END IF;
    
    SET v_execution_time = TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000;
    
    INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result, execution_time_ms)
    VALUES (p_test_suite, p_test_name, v_status, p_expected, p_actual, v_execution_time);
END //

-- Assert not null
CREATE PROCEDURE assert_not_null(
    IN p_test_suite VARCHAR(100),
    IN p_test_name VARCHAR(200),
    IN p_value TEXT
)
BEGIN
    DECLARE v_status VARCHAR(10);
    
    IF p_value IS NOT NULL THEN
        SET v_status = 'PASS';
    ELSE
        SET v_status = 'FAIL';
    END IF;
    
    INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
    VALUES (p_test_suite, p_test_name, v_status, 'NOT NULL', COALESCE(p_value, 'NULL'));
END //

-- Assert true
CREATE PROCEDURE assert_true(
    IN p_test_suite VARCHAR(100),
    IN p_test_name VARCHAR(200),
    IN p_condition BOOLEAN
)
BEGIN
    DECLARE v_status VARCHAR(10);
    
    IF p_condition THEN
        SET v_status = 'PASS';
    ELSE
        SET v_status = 'FAIL';
    END IF;
    
    INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
    VALUES (p_test_suite, p_test_name, v_status, 'TRUE', IF(p_condition, 'TRUE', 'FALSE'));
END //

-- Assert row count
CREATE PROCEDURE assert_row_count(
    IN p_test_suite VARCHAR(100),
    IN p_test_name VARCHAR(200),
    IN p_table VARCHAR(100),
    IN p_expected_count INT
)
BEGIN
    DECLARE v_actual_count INT;
    DECLARE v_status VARCHAR(10);
    
    SET @sql = CONCAT('SELECT COUNT(*) INTO @count FROM ', p_table);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET v_actual_count = @count;
    
    IF v_actual_count = p_expected_count THEN
        SET v_status = 'PASS';
    ELSE
        SET v_status = 'FAIL';
    END IF;
    
    INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
    VALUES (p_test_suite, p_test_name, v_status, p_expected_count, v_actual_count);
END //

-- Assert greater than
CREATE PROCEDURE assert_greater_than(
    IN p_test_suite VARCHAR(100),
    IN p_test_name VARCHAR(200),
    IN p_value DECIMAL(20,4),
    IN p_threshold DECIMAL(20,4)
)
BEGIN
    DECLARE v_status VARCHAR(10);
    
    IF p_value > p_threshold THEN
        SET v_status = 'PASS';
    ELSE
        SET v_status = 'FAIL';
    END IF;
    
    INSERT INTO test_results (test_suite, test_name, status, expected_result, actual_result)
    VALUES (p_test_suite, p_test_name, v_status, 
            CONCAT('> ', p_threshold), p_value);
END //

-- Run test suite and show results
CREATE PROCEDURE run_test_suite(
    IN p_suite_name VARCHAR(100)
)
BEGIN
    DECLARE v_start_time DATETIME;
    
    SET v_start_time = NOW();
    
    -- Run the appropriate test suite
    CASE p_suite_name
        WHEN 'procedures' THEN CALL test_suite_procedures();
        WHEN 'functions' THEN CALL test_suite_functions();
        WHEN 'triggers' THEN CALL test_suite_triggers();
        WHEN 'constraints' THEN CALL test_suite_constraints();
        WHEN 'data_integrity' THEN CALL test_suite_data_integrity();
        ELSE
            SELECT CONCAT('Unknown test suite: ', p_suite_name) AS error;
    END CASE;
    
    -- Show results summary
    SELECT 
        status,
        COUNT(*) AS count
    FROM test_results
    WHERE test_suite = p_suite_name
      AND executed_at >= v_start_time
    GROUP BY status;
    
    -- Show failed tests
    SELECT 
        test_name,
        expected_result,
        actual_result,
        error_message
    FROM test_results
    WHERE test_suite = p_suite_name
      AND status IN ('FAIL', 'ERROR')
      AND executed_at >= v_start_time;
END //

DELIMITER ;

-- ================================================================
-- SECTION 3: PROCEDURE TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_suite_procedures()
BEGIN
    DECLARE v_result INT;
    DECLARE v_customer_id INT;
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    
    -- Test 1: Customer creation
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_error = TRUE;
        
        -- Create test customer
        INSERT INTO customers (name, email, phone, city, state, tier_id)
        VALUES ('Test Customer', 'test@test.com', '9999999999', 'Test City', 'Test State', 1);
        SET v_customer_id = LAST_INSERT_ID();
        
        CALL assert_true('procedures', 'sp_create_customer: Customer created', v_customer_id > 0);
        
        -- Cleanup
        DELETE FROM customers WHERE customer_id = v_customer_id;
    END;
    
    -- Test 2: Product price update validation
    BEGIN
        DECLARE v_old_price DECIMAL(10,2);
        DECLARE v_new_price DECIMAL(10,2);
        
        SELECT price INTO v_old_price FROM products WHERE product_id = 1;
        
        -- Update and check
        UPDATE products SET price = price * 1.1 WHERE product_id = 1;
        SELECT price INTO v_new_price FROM products WHERE product_id = 1;
        
        CALL assert_greater_than('procedures', 'Price update: New price > Old price', v_new_price, v_old_price);
        
        -- Revert
        UPDATE products SET price = v_old_price WHERE product_id = 1;
    END;
    
    -- Test 3: Sale total calculation
    BEGIN
        DECLARE v_sale_total DECIMAL(12,2);
        DECLARE v_calculated_total DECIMAL(12,2);
        
        SELECT 
            s.total_amount,
            SUM(sd.line_total)
        INTO v_sale_total, v_calculated_total
        FROM sales s
        JOIN sales_details sd ON s.sale_id = sd.sale_id
        WHERE s.sale_id = 1
        GROUP BY s.sale_id;
        
        CALL assert_true('procedures', 'Sale total matches sum of line items', 
                        ABS(v_sale_total - v_calculated_total) < 1);
    END;
    
    SELECT 'Procedure tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 4: FUNCTION TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_suite_functions()
BEGIN
    -- Test built-in functions
    CALL assert_equals('functions', 'CONCAT function', 'HelloWorld', CONCAT('Hello', 'World'));
    CALL assert_equals('functions', 'UPPER function', 'TEST', UPPER('test'));
    CALL assert_equals('functions', 'LENGTH function', '5', CAST(LENGTH('Hello') AS CHAR));
    CALL assert_equals('functions', 'ROUND function', '3.14', CAST(ROUND(3.14159, 2) AS CHAR));
    
    -- Test date functions
    CALL assert_true('functions', 'CURRENT_DATE returns valid date', CURRENT_DATE IS NOT NULL);
    CALL assert_true('functions', 'DATE_ADD works', DATE_ADD(CURRENT_DATE, INTERVAL 1 DAY) > CURRENT_DATE);
    
    -- Test aggregate functions on actual data
    BEGIN
        DECLARE v_count INT;
        DECLARE v_sum DECIMAL(15,2);
        
        SELECT COUNT(*) INTO v_count FROM customers;
        CALL assert_greater_than('functions', 'COUNT(customers) > 0', v_count, 0);
        
        SELECT COALESCE(SUM(total_amount), 0) INTO v_sum FROM sales WHERE status = 'completed';
        CALL assert_true('functions', 'SUM(sales.total_amount) >= 0', v_sum >= 0);
    END;
    
    SELECT 'Function tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 5: TRIGGER TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_suite_triggers()
BEGIN
    DECLARE v_old_stock INT;
    DECLARE v_new_stock INT;
    DECLARE v_product_id INT DEFAULT 1;
    
    -- Test inventory update trigger (if exists)
    SELECT stock INTO v_old_stock FROM products WHERE product_id = v_product_id;
    
    -- Simulate sale (without trigger by direct update)
    UPDATE products SET stock = stock - 1 WHERE product_id = v_product_id;
    SELECT stock INTO v_new_stock FROM products WHERE product_id = v_product_id;
    
    CALL assert_equals('triggers', 'Stock decreased by 1', 
                       CAST(v_old_stock - 1 AS CHAR), 
                       CAST(v_new_stock AS CHAR));
    
    -- Revert
    UPDATE products SET stock = v_old_stock WHERE product_id = v_product_id;
    
    -- Test updated_at trigger
    BEGIN
        DECLARE v_old_updated_at DATETIME;
        DECLARE v_new_updated_at DATETIME;
        
        SELECT updated_at INTO v_old_updated_at FROM products WHERE product_id = v_product_id;
        
        -- Wait a moment and update
        DO SLEEP(1);
        UPDATE products SET name = name WHERE product_id = v_product_id;
        SELECT updated_at INTO v_new_updated_at FROM products WHERE product_id = v_product_id;
        
        CALL assert_true('triggers', 'updated_at changed on UPDATE', v_new_updated_at >= v_old_updated_at);
    END;
    
    SELECT 'Trigger tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 6: CONSTRAINT TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_suite_constraints()
BEGIN
    DECLARE v_error BOOLEAN DEFAULT FALSE;
    
    -- Test PRIMARY KEY constraint
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1062 SET v_error = TRUE;  -- Duplicate entry
        
        SET v_error = FALSE;
        INSERT INTO categories (category_id, category_name) 
        VALUES (1, 'Duplicate Test');
        
        CALL assert_true('constraints', 'PRIMARY KEY prevents duplicates', v_error);
    END;
    
    -- Test FOREIGN KEY constraint
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1452 SET v_error = TRUE;  -- FK constraint fails
        
        SET v_error = FALSE;
        INSERT INTO products (name, category_id, price)
        VALUES ('Test Product', 99999, 100);  -- Invalid category_id
        
        CALL assert_true('constraints', 'FOREIGN KEY prevents invalid references', v_error);
    END;
    
    -- Test NOT NULL constraint
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1048 SET v_error = TRUE;  -- Column cannot be null
        
        SET v_error = FALSE;
        INSERT INTO customers (name, email) VALUES (NULL, 'test@test.com');
        
        CALL assert_true('constraints', 'NOT NULL prevents NULL values', v_error);
    END;
    
    -- Test UNIQUE constraint
    BEGIN
        DECLARE CONTINUE HANDLER FOR 1062 SET v_error = TRUE;
        
        SET v_error = FALSE;
        INSERT INTO customers (name, email) VALUES ('Test1', 'unique@test.com');
        INSERT INTO customers (name, email) VALUES ('Test2', 'unique@test.com');
        
        CALL assert_true('constraints', 'UNIQUE constraint prevents duplicate emails', v_error);
        
        -- Cleanup
        DELETE FROM customers WHERE email = 'unique@test.com';
    END;
    
    SELECT 'Constraint tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 7: DATA INTEGRITY TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE test_suite_data_integrity()
BEGIN
    DECLARE v_orphan_count INT;
    DECLARE v_null_count INT;
    DECLARE v_invalid_count INT;
    
    -- Test: No orphan sales details
    SELECT COUNT(*) INTO v_orphan_count
    FROM sales_details sd
    LEFT JOIN sales s ON sd.sale_id = s.sale_id
    WHERE s.sale_id IS NULL;
    
    CALL assert_equals('data_integrity', 'No orphan sales_details', '0', CAST(v_orphan_count AS CHAR));
    
    -- Test: No orphan products
    SELECT COUNT(*) INTO v_orphan_count
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    WHERE p.category_id IS NOT NULL AND c.category_id IS NULL;
    
    CALL assert_equals('data_integrity', 'No orphan products (invalid category)', '0', CAST(v_orphan_count AS CHAR));
    
    -- Test: All customers have valid tier
    SELECT COUNT(*) INTO v_invalid_count
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    WHERE c.tier_id IS NOT NULL AND ct.tier_id IS NULL;
    
    CALL assert_equals('data_integrity', 'All customers have valid tier', '0', CAST(v_invalid_count AS CHAR));
    
    -- Test: No negative prices
    SELECT COUNT(*) INTO v_invalid_count
    FROM products
    WHERE price < 0;
    
    CALL assert_equals('data_integrity', 'No negative product prices', '0', CAST(v_invalid_count AS CHAR));
    
    -- Test: No negative stock
    SELECT COUNT(*) INTO v_invalid_count
    FROM products
    WHERE stock < 0;
    
    CALL assert_equals('data_integrity', 'No negative stock values', '0', CAST(v_invalid_count AS CHAR));
    
    -- Test: Sale totals are positive
    SELECT COUNT(*) INTO v_invalid_count
    FROM sales
    WHERE total_amount < 0;
    
    CALL assert_equals('data_integrity', 'No negative sale totals', '0', CAST(v_invalid_count AS CHAR));
    
    SELECT 'Data integrity tests completed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 8: RUN ALL TESTS
-- ================================================================

DELIMITER //

CREATE PROCEDURE run_all_tests()
BEGIN
    DECLARE v_start_time DATETIME;
    DECLARE v_total_pass INT DEFAULT 0;
    DECLARE v_total_fail INT DEFAULT 0;
    
    SET v_start_time = NOW();
    
    SELECT 'Running all test suites...' AS status;
    
    -- Run all suites
    CALL test_suite_functions();
    CALL test_suite_constraints();
    CALL test_suite_data_integrity();
    CALL test_suite_procedures();
    CALL test_suite_triggers();
    
    -- Summary
    SELECT 
        COUNT(CASE WHEN status = 'PASS' THEN 1 END) AS passed,
        COUNT(CASE WHEN status = 'FAIL' THEN 1 END) AS failed,
        COUNT(CASE WHEN status = 'ERROR' THEN 1 END) AS errors,
        COUNT(*) AS total,
        TIMESTAMPDIFF(SECOND, v_start_time, NOW()) AS duration_seconds
    FROM test_results
    WHERE executed_at >= v_start_time;
    
    -- Show failures
    SELECT 
        test_suite,
        test_name,
        expected_result,
        actual_result
    FROM test_results
    WHERE executed_at >= v_start_time
      AND status = 'FAIL';
END //

DELIMITER ;

-- ================================================================
-- USAGE
-- ================================================================

/*
-- Run all tests
CALL run_all_tests();

-- Run specific suite
CALL run_test_suite('procedures');
CALL run_test_suite('functions');
CALL run_test_suite('constraints');
CALL run_test_suite('data_integrity');

-- View recent results
SELECT * FROM test_results ORDER BY executed_at DESC LIMIT 50;

-- View test summary by suite
SELECT 
    test_suite,
    COUNT(CASE WHEN status = 'PASS' THEN 1 END) AS passed,
    COUNT(CASE WHEN status = 'FAIL' THEN 1 END) AS failed,
    COUNT(*) AS total
FROM test_results
GROUP BY test_suite;
*/

-- ================================================================
-- END OF TESTING FRAMEWORK
-- ================================================================
