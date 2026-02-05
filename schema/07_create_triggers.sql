-- ================================================================
-- TRIGGER CREATION SCRIPT
-- Creates all triggers for automatic data management
-- Run after: 02_create_tables.sql
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SALES TRIGGERS
-- ================================================================

-- Trigger: Update Customer Total Spent After New Sale
DELIMITER //
CREATE TRIGGER trg_after_sale_insert
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE customers
        SET total_spent = total_spent + NEW.total_amount,
            last_purchase_date = DATE(NEW.sale_date),
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
    END IF;
END //
DELIMITER ;

-- Trigger: Adjust Customer Spending on Sale Update
DELIMITER //
CREATE TRIGGER trg_after_sale_update
AFTER UPDATE ON sales
FOR EACH ROW
BEGIN
    DECLARE v_amount_diff DECIMAL(12,2);
    
    -- If status changed to completed
    IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
        UPDATE customers
        SET total_spent = total_spent + NEW.total_amount,
            last_purchase_date = DATE(NEW.sale_date),
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
    
    -- If status changed from completed to refunded/cancelled
    ELSEIF OLD.status = 'completed' AND NEW.status IN ('refunded', 'cancelled') THEN
        UPDATE customers
        SET total_spent = total_spent - OLD.total_amount,
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
    
    -- If amount changed on completed sale
    ELSEIF OLD.status = 'completed' AND NEW.status = 'completed' 
           AND OLD.total_amount != NEW.total_amount THEN
        SET v_amount_diff = NEW.total_amount - OLD.total_amount;
        UPDATE customers
        SET total_spent = total_spent + v_amount_diff,
            updated_at = CURRENT_TIMESTAMP
        WHERE customer_id = NEW.customer_id;
    END IF;
END //
DELIMITER ;

-- ================================================================
-- SALES DETAILS TRIGGERS
-- ================================================================

-- Trigger: Record Inventory Transaction and Update Stock on Sale Detail Insert
DELIMITER //
CREATE TRIGGER trg_after_sale_detail_insert
AFTER INSERT ON sales_details
FOR EACH ROW
BEGIN
    -- Record inventory transaction
    INSERT INTO inventory_transactions (
        product_id, 
        transaction_type, 
        quantity, 
        reference_id,
        reference_type,
        notes
    )
    VALUES (
        NEW.product_id, 
        'sale', 
        -NEW.quantity,
        NEW.sale_id,
        'sale',
        CONCAT('Sale ID: ', NEW.sale_id, ', Detail ID: ', NEW.sale_detail_id)
    );
    
    -- Update product stock
    UPDATE products 
    SET stock = stock - NEW.quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

-- Trigger: Calculate Line Total Before Insert
DELIMITER //
CREATE TRIGGER trg_before_sale_detail_insert
BEFORE INSERT ON sales_details
FOR EACH ROW
BEGIN
    -- Auto-calculate line total if not provided
    IF NEW.line_total IS NULL OR NEW.line_total = 0 THEN
        SET NEW.line_total = NEW.unit_price * NEW.quantity * (1 - COALESCE(NEW.discount, 0) / 100);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- PRODUCT TRIGGERS
-- ================================================================

-- Trigger: Prevent Deletion of Products with Sales History
DELIMITER //
CREATE TRIGGER trg_before_product_delete
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    DECLARE v_sales_count INT;
    
    SELECT COUNT(*) INTO v_sales_count
    FROM sales_details
    WHERE product_id = OLD.product_id;
    
    IF v_sales_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete product with existing sales records. Deactivate instead.';
    END IF;
END //
DELIMITER ;

-- Trigger: Log Low Stock Alert
DELIMITER //
CREATE TRIGGER trg_after_product_update_stock
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    -- Log when stock falls below reorder level
    IF NEW.stock <= NEW.reorder_level AND OLD.stock > OLD.reorder_level THEN
        INSERT INTO system_logs (log_level, message, context)
        VALUES (
            'WARNING',
            CONCAT('Low stock alert for product: ', NEW.name),
            JSON_OBJECT(
                'product_id', NEW.product_id,
                'product_name', NEW.name,
                'current_stock', NEW.stock,
                'reorder_level', NEW.reorder_level
            )
        );
    END IF;
    
    -- Log when stock is depleted
    IF NEW.stock = 0 AND OLD.stock > 0 THEN
        INSERT INTO system_logs (log_level, message, context)
        VALUES (
            'ERROR',
            CONCAT('Out of stock: ', NEW.name),
            JSON_OBJECT(
                'product_id', NEW.product_id,
                'product_name', NEW.name
            )
        );
    END IF;
END //
DELIMITER ;

-- ================================================================
-- CUSTOMER TRIGGERS
-- ================================================================

-- Trigger: Auto-update Customer Tier Based on Spending
DELIMITER //
CREATE TRIGGER trg_after_customer_spending_update
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    DECLARE v_new_tier_id INT;
    
    -- Only check if total_spent changed
    IF NEW.total_spent != OLD.total_spent THEN
        -- Find appropriate tier
        SELECT tier_id INTO v_new_tier_id
        FROM customer_tiers
        WHERE NEW.total_spent >= min_purchases
        ORDER BY min_purchases DESC
        LIMIT 1;
        
        -- Update tier if different (use separate update to avoid recursion)
        IF v_new_tier_id IS NOT NULL AND v_new_tier_id != NEW.tier_id THEN
            -- Log tier change
            INSERT INTO system_logs (log_level, message, context)
            VALUES (
                'INFO',
                CONCAT('Customer tier upgraded: ', NEW.name),
                JSON_OBJECT(
                    'customer_id', NEW.customer_id,
                    'old_tier', OLD.tier_id,
                    'new_tier', v_new_tier_id,
                    'total_spent', NEW.total_spent
                )
            );
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger: Prevent Deletion of Customers with Orders
DELIMITER //
CREATE TRIGGER trg_before_customer_delete
BEFORE DELETE ON customers
FOR EACH ROW
BEGIN
    DECLARE v_order_count INT;
    
    SELECT COUNT(*) INTO v_order_count
    FROM sales
    WHERE customer_id = OLD.customer_id;
    
    IF v_order_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete customer with order history. Deactivate instead.';
    END IF;
END //
DELIMITER ;

-- ================================================================
-- EMPLOYEE TRIGGERS
-- ================================================================

-- Trigger: Validate Manager Assignment
DELIMITER //
CREATE TRIGGER trg_before_employee_insert
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    DECLARE v_manager_exists INT;
    
    IF NEW.manager_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_manager_exists
        FROM employees
        WHERE employee_id = NEW.manager_id;
        
        IF v_manager_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Manager ID does not exist';
        END IF;
    END IF;
END //
DELIMITER ;

-- Trigger: Prevent Self-Reference as Manager
DELIMITER //
CREATE TRIGGER trg_before_employee_update
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF NEW.manager_id = NEW.employee_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Employee cannot be their own manager';
    END IF;
END //
DELIMITER ;

-- ================================================================
-- AUDIT TRIGGERS
-- ================================================================

-- Trigger: Audit Sales Changes
DELIMITER //
CREATE TRIGGER trg_audit_sales_update
AFTER UPDATE ON sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name,
        action_type,
        record_id,
        old_values,
        new_values,
        changed_by
    )
    VALUES (
        'sales',
        'UPDATE',
        NEW.sale_id,
        JSON_OBJECT(
            'status', OLD.status,
            'total_amount', OLD.total_amount,
            'discount_amount', OLD.discount_amount
        ),
        JSON_OBJECT(
            'status', NEW.status,
            'total_amount', NEW.total_amount,
            'discount_amount', NEW.discount_amount
        ),
        CURRENT_USER()
    );
END //
DELIMITER ;

-- Trigger: Audit Product Price Changes
DELIMITER //
CREATE TRIGGER trg_audit_product_price
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
    IF OLD.price != NEW.price OR OLD.cost_price != NEW.cost_price THEN
        INSERT INTO audit_log (
            table_name,
            action_type,
            record_id,
            old_values,
            new_values,
            changed_by
        )
        VALUES (
            'products',
            'UPDATE',
            NEW.product_id,
            JSON_OBJECT(
                'price', OLD.price,
                'cost_price', OLD.cost_price
            ),
            JSON_OBJECT(
                'price', NEW.price,
                'cost_price', NEW.cost_price
            ),
            CURRENT_USER()
        );
    END IF;
END //
DELIMITER ;

-- ================================================================
-- VERIFICATION
-- ================================================================

DELIMITER ;

SELECT 'All triggers created successfully!' AS status;

-- List all triggers
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION AS event,
    EVENT_OBJECT_TABLE AS table_name,
    ACTION_TIMING AS timing
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'retail_sales_advanced'
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;
