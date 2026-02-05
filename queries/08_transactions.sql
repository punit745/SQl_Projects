-- ================================================================
-- TRANSACTIONS AND ERROR HANDLING IN MySQL
-- Demonstrating ACID properties, transaction control, error handling
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: BASIC TRANSACTION CONTROL
-- ================================================================

-- Simple Transaction Example
START TRANSACTION;

-- Insert a new customer
INSERT INTO customers (name, email, phone, city, state, tier_id)
VALUES ('Test Customer', 'test@example.com', '1234567890', 'Test City', 'Test State', 1);

-- Check if insert was successful
SELECT * FROM customers WHERE email = 'test@example.com';

-- If everything looks good, commit
COMMIT;

-- OR if something went wrong, rollback
-- ROLLBACK;

-- ================================================================
-- SECTION 2: TRANSACTION WITH MULTIPLE OPERATIONS
-- ================================================================

-- Transfer funds / balance between accounts (classic example)
DELIMITER //
CREATE PROCEDURE sp_transfer_inventory(
    IN p_from_product INT,
    IN p_to_product INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_from_stock INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check source stock
    SELECT stock INTO v_from_stock 
    FROM products 
    WHERE product_id = p_from_product 
    FOR UPDATE;  -- Lock the row
    
    IF v_from_stock < p_quantity THEN
        ROLLBACK;
        SELECT 'Insufficient stock in source product' AS error;
    ELSE
        -- Reduce stock from source
        UPDATE products 
        SET stock = stock - p_quantity 
        WHERE product_id = p_from_product;
        
        -- Add stock to destination
        UPDATE products 
        SET stock = stock + p_quantity 
        WHERE product_id = p_to_product;
        
        -- Record transactions
        INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes)
        VALUES (p_from_product, 'transfer', -p_quantity, CONCAT('Transfer to product ', p_to_product));
        
        INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes)
        VALUES (p_to_product, 'transfer', p_quantity, CONCAT('Transfer from product ', p_from_product));
        
        COMMIT;
        SELECT 'Transfer completed successfully' AS status;
    END IF;
END //
DELIMITER ;

-- ================================================================
-- SECTION 3: SAVEPOINTS
-- ================================================================

-- Savepoints allow partial rollbacks within a transaction
START TRANSACTION;

-- First operation
INSERT INTO categories (category_name, description) 
VALUES ('Test Category 1', 'First test category');

SAVEPOINT sp_first_category;

-- Second operation
INSERT INTO categories (category_name, description) 
VALUES ('Test Category 2', 'Second test category');

SAVEPOINT sp_second_category;

-- Third operation - let's say this one needs to be undone
INSERT INTO categories (category_name, description) 
VALUES ('Test Category 3', 'Third test category');

-- Oops, rollback only the third insert
ROLLBACK TO SAVEPOINT sp_second_category;

-- First two inserts are still pending
-- Commit them
COMMIT;

-- Release savepoint (optional, cleaned up on commit/rollback anyway)
-- RELEASE SAVEPOINT sp_first_category;

-- ================================================================
-- SECTION 4: TRANSACTION ISOLATION LEVELS
-- ================================================================

-- View current isolation level
SELECT @@transaction_isolation;

-- Set isolation level for current session
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  -- MySQL default
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Set for next transaction only
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

/*
Isolation Levels Explained:

1. READ UNCOMMITTED
   - Allows dirty reads (reading uncommitted data from other transactions)
   - Fastest but least safe
   
2. READ COMMITTED
   - Only read committed data
   - Prevents dirty reads
   - Non-repeatable reads possible
   
3. REPEATABLE READ (MySQL Default)
   - Consistent reads within transaction
   - Prevents dirty and non-repeatable reads
   - Phantom reads possible
   
4. SERIALIZABLE
   - Highest isolation
   - All reads are locking reads
   - Slowest but safest
*/

-- Example: Serializable transaction
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;

SELECT * FROM products WHERE category_id = 1 FOR UPDATE;

-- Other transactions trying to modify these rows will wait or fail
-- ... do your work ...

COMMIT;

-- ================================================================
-- SECTION 5: LOCKING
-- ================================================================

-- Shared lock (for reading)
SELECT * FROM products WHERE product_id = 1 LOCK IN SHARE MODE;

-- Exclusive lock (for updating)
SELECT * FROM products WHERE product_id = 1 FOR UPDATE;

-- Skip locked rows (useful for queue processing)
SELECT * FROM sales 
WHERE status = 'pending' 
ORDER BY sale_id 
LIMIT 1 
FOR UPDATE SKIP LOCKED;

-- No wait (fail immediately if lock not available)
SELECT * FROM products WHERE product_id = 1 FOR UPDATE NOWAIT;

-- ================================================================
-- SECTION 6: ERROR HANDLING WITH HANDLERS
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_safe_sale(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    OUT p_success BOOLEAN,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_sale_id INT;
    
    -- Declare handlers for different error conditions
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = FALSE;
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    DECLARE EXIT HANDLER FOR SQLWARNING
    BEGIN
        ROLLBACK;
        SET p_success = FALSE;
        SET p_message = 'A SQL warning occurred';
    END;
    
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        ROLLBACK;
        SET p_success = FALSE;
        SET p_message = 'Required data not found';
    END;
    
    -- Initialize
    SET p_success = FALSE;
    SET p_message = '';
    
    START TRANSACTION;
    
    -- Check stock
    SELECT stock, price INTO v_stock, v_price
    FROM products 
    WHERE product_id = p_product_id
    FOR UPDATE;
    
    IF v_stock < p_quantity THEN
        SET p_message = 'Insufficient stock available';
        ROLLBACK;
    ELSE
        -- Create sale
        INSERT INTO sales (customer_id, subtotal, total_amount, status)
        VALUES (p_customer_id, v_price * p_quantity, v_price * p_quantity, 'completed');
        
        SET v_sale_id = LAST_INSERT_ID();
        
        -- Add sale detail
        INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, line_total)
        VALUES (v_sale_id, p_product_id, p_quantity, v_price, v_price * p_quantity);
        
        -- Update stock
        UPDATE products SET stock = stock - p_quantity WHERE product_id = p_product_id;
        
        COMMIT;
        SET p_success = TRUE;
        SET p_message = CONCAT('Sale created successfully. Sale ID: ', v_sale_id);
    END IF;
END //
DELIMITER ;

-- Call the procedure
CALL sp_safe_sale(1, 1, 2, @success, @message);
SELECT @success AS success, @message AS message;

-- ================================================================
-- SECTION 7: SIGNAL AND RESIGNAL
-- ================================================================

-- Using SIGNAL to raise custom errors
DELIMITER //
CREATE PROCEDURE sp_validate_sale(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_customer_exists INT;
    DECLARE v_product_exists INT;
    DECLARE v_stock INT;
    
    -- Validate customer exists
    SELECT COUNT(*) INTO v_customer_exists 
    FROM customers 
    WHERE customer_id = p_customer_id AND is_active = TRUE;
    
    IF v_customer_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid customer ID or customer is inactive',
            MYSQL_ERRNO = 1001;
    END IF;
    
    -- Validate product exists
    SELECT COUNT(*), COALESCE(MAX(stock), 0) INTO v_product_exists, v_stock
    FROM products 
    WHERE product_id = p_product_id AND is_active = TRUE;
    
    IF v_product_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid product ID or product is inactive',
            MYSQL_ERRNO = 1002;
    END IF;
    
    -- Validate quantity
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Quantity must be greater than zero',
            MYSQL_ERRNO = 1003;
    END IF;
    
    -- Validate stock
    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock available',
            MYSQL_ERRNO = 1004;
    END IF;
    
    SELECT 'Validation passed' AS status;
END //
DELIMITER ;

-- Using RESIGNAL to re-throw errors with additional context
DELIMITER //
CREATE PROCEDURE sp_process_order(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Get the original error
        GET DIAGNOSTICS CONDITION 1 @err_msg = MESSAGE_TEXT;
        
        -- Re-signal with additional context
        RESIGNAL SET 
            MESSAGE_TEXT = CONCAT('Order processing failed: ', @err_msg);
    END;
    
    -- Validate first
    CALL sp_validate_sale(p_customer_id, p_product_id, p_quantity);
    
    -- Process the order (simplified)
    SELECT 'Order processed successfully' AS status;
END //
DELIMITER ;

-- ================================================================
-- SECTION 8: CONDITION HANDLING
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_comprehensive_error_handling()
BEGIN
    -- Declare conditions
    DECLARE duplicate_key CONDITION FOR 1062;
    DECLARE table_not_found CONDITION FOR 1146;
    DECLARE column_not_found CONDITION FOR 1054;
    
    -- Handler for duplicate key
    DECLARE CONTINUE HANDLER FOR duplicate_key
    BEGIN
        INSERT INTO system_logs (log_level, message)
        VALUES ('WARNING', 'Duplicate key violation - skipping');
    END;
    
    -- Handler for specific SQLSTATE
    DECLARE CONTINUE HANDLER FOR SQLSTATE '23000'
    BEGIN
        INSERT INTO system_logs (log_level, message)
        VALUES ('WARNING', 'Constraint violation');
    END;
    
    -- Handler for all SQL exceptions (catch-all)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            @errno = MYSQL_ERRNO,
            @msg = MESSAGE_TEXT,
            @state = RETURNED_SQLSTATE;
        
        INSERT INTO system_logs (log_level, message, context)
        VALUES ('ERROR', @msg, JSON_OBJECT('errno', @errno, 'sqlstate', @state));
        
        RESIGNAL;
    END;
    
    -- Your business logic here
    SELECT 'Processing...' AS status;
END //
DELIMITER ;

-- ================================================================
-- SECTION 9: ATOMIC DDL
-- ================================================================

-- Note: MySQL 8.0+ supports atomic DDL for certain operations
-- This means DDL statements are transactional

-- Example: Creating multiple tables atomically
START TRANSACTION;

CREATE TABLE IF NOT EXISTS temp_table_1 (id INT PRIMARY KEY);
CREATE TABLE IF NOT EXISTS temp_table_2 (id INT PRIMARY KEY);

-- If any CREATE fails, all are rolled back
COMMIT;

-- Clean up
-- DROP TABLE IF EXISTS temp_table_1, temp_table_2;

-- ================================================================
-- SECTION 10: BEST PRACTICES
-- ================================================================

/*
Transaction Best Practices:

1. Keep transactions short
   - Long transactions hold locks longer
   - Can cause blocking and deadlocks

2. Access resources in consistent order
   - Helps prevent deadlocks
   - e.g., always lock table A before table B

3. Use appropriate isolation level
   - Don't use SERIALIZABLE unless necessary
   - READ COMMITTED is often sufficient

4. Handle errors properly
   - Always have error handlers
   - Always ROLLBACK on error

5. Test for deadlocks
   - Your code should handle deadlock retries
   - Example below:
*/

DELIMITER //
CREATE PROCEDURE sp_with_deadlock_retry(
    IN p_max_retries INT
)
BEGIN
    DECLARE v_retry_count INT DEFAULT 0;
    DECLARE v_success BOOLEAN DEFAULT FALSE;
    
    retry_loop: WHILE v_retry_count < p_max_retries AND NOT v_success DO
        BEGIN
            DECLARE EXIT HANDLER FOR 1213  -- Deadlock error
            BEGIN
                SET v_retry_count = v_retry_count + 1;
                
                IF v_retry_count < p_max_retries THEN
                    -- Wait a bit before retrying
                    DO SLEEP(0.1 * v_retry_count);
                END IF;
            END;
            
            START TRANSACTION;
            
            -- Your transaction logic here
            SELECT 'Doing work...' AS status;
            
            COMMIT;
            SET v_success = TRUE;
        END;
    END WHILE;
    
    IF NOT v_success THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction failed after maximum retries';
    END IF;
END //
DELIMITER ;

-- ================================================================
-- END OF TRANSACTIONS AND ERROR HANDLING
-- ================================================================
