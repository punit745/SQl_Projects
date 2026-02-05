-- ================================================================
-- STORED PROCEDURES SCRIPT
-- Creates all stored procedures for business logic
-- Run after: 02_create_tables.sql
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SALES PROCEDURES
-- ================================================================

-- Procedure: Add New Sale with Automatic Calculations
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
    DECLARE v_stock_available INT;
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check stock availability
    SELECT stock INTO v_stock_available 
    FROM products 
    WHERE product_id = p_product_id FOR UPDATE;
    
    IF v_stock_available < p_quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient stock available';
    END IF;
    
    -- Get product price
    SELECT price INTO v_unit_price 
    FROM products 
    WHERE product_id = p_product_id;
    
    -- Get customer discount based on tier
    SELECT COALESCE(ct.discount_percentage, 0) INTO v_discount_pct 
    FROM customer_tiers ct
    JOIN customers c ON ct.tier_id = c.tier_id
    WHERE c.customer_id = p_customer_id;
    
    -- Calculate line total
    SET v_line_total = v_unit_price * p_quantity * (1 - v_discount_pct/100);
    
    -- Insert sale header
    INSERT INTO sales (
        customer_id, employee_id, payment_method_id, 
        subtotal, discount_amount, tax_amount, total_amount, status
    )
    VALUES (
        p_customer_id, p_employee_id, p_payment_method_id,
        v_unit_price * p_quantity,
        (v_unit_price * p_quantity * v_discount_pct / 100),
        (v_line_total * v_tax_rate / 100),
        v_line_total * (1 + v_tax_rate/100),
        'completed'
    );
    
    SET v_sale_id = LAST_INSERT_ID();
    
    -- Insert sale detail
    INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, discount, line_total)
    VALUES (v_sale_id, p_product_id, p_quantity, v_unit_price, v_discount_pct, v_line_total);
    
    -- Update product stock
    UPDATE products 
    SET stock = stock - p_quantity 
    WHERE product_id = p_product_id;
    
    -- Record inventory transaction
    INSERT INTO inventory_transactions (product_id, transaction_type, quantity, reference_id, reference_type, notes)
    VALUES (p_product_id, 'sale', -p_quantity, v_sale_id, 'sale', CONCAT('Sale ID: ', v_sale_id));
    
    COMMIT;
    
    SELECT v_sale_id AS new_sale_id, 'Sale completed successfully' AS message;
END //
DELIMITER ;

-- Procedure: Add Multiple Items to a Sale
DELIMITER //
CREATE PROCEDURE sp_add_sale_multi_items(
    IN p_customer_id INT,
    IN p_employee_id INT,
    IN p_payment_method_id INT,
    IN p_items JSON
)
BEGIN
    DECLARE v_sale_id INT;
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_discount_amount DECIMAL(10,2) DEFAULT 0;
    DECLARE v_discount_pct DECIMAL(5,2);
    DECLARE v_tax_rate DECIMAL(5,2) DEFAULT 18.00;
    DECLARE v_item_count INT;
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_line_total DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get customer discount
    SELECT COALESCE(ct.discount_percentage, 0) INTO v_discount_pct 
    FROM customer_tiers ct
    JOIN customers c ON ct.tier_id = c.tier_id
    WHERE c.customer_id = p_customer_id;
    
    -- Calculate subtotal from items JSON
    SET v_item_count = JSON_LENGTH(p_items);
    
    -- Insert sale header (will update totals later)
    INSERT INTO sales (customer_id, employee_id, payment_method_id, status)
    VALUES (p_customer_id, p_employee_id, p_payment_method_id, 'pending');
    
    SET v_sale_id = LAST_INSERT_ID();
    
    -- Process each item
    WHILE v_i < v_item_count DO
        SET v_product_id = JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id'));
        SET v_quantity = JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity'));
        
        -- Get product price
        SELECT price INTO v_unit_price FROM products WHERE product_id = v_product_id;
        
        SET v_line_total = v_unit_price * v_quantity * (1 - v_discount_pct/100);
        SET v_subtotal = v_subtotal + (v_unit_price * v_quantity);
        SET v_discount_amount = v_discount_amount + (v_unit_price * v_quantity * v_discount_pct / 100);
        
        -- Insert sale detail
        INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, discount, line_total)
        VALUES (v_sale_id, v_product_id, v_quantity, v_unit_price, v_discount_pct, v_line_total);
        
        -- Update stock
        UPDATE products SET stock = stock - v_quantity WHERE product_id = v_product_id;
        
        SET v_i = v_i + 1;
    END WHILE;
    
    -- Update sale totals
    UPDATE sales SET
        subtotal = v_subtotal,
        discount_amount = v_discount_amount,
        tax_amount = (v_subtotal - v_discount_amount) * v_tax_rate / 100,
        total_amount = (v_subtotal - v_discount_amount) * (1 + v_tax_rate / 100),
        status = 'completed'
    WHERE sale_id = v_sale_id;
    
    COMMIT;
    
    SELECT v_sale_id AS new_sale_id, v_item_count AS items_added;
END //
DELIMITER ;

-- Procedure: Process Return/Refund
DELIMITER //
CREATE PROCEDURE sp_process_return(
    IN p_sale_id INT,
    IN p_reason TEXT
)
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_total_amount DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get sale details
    SELECT customer_id, total_amount INTO v_customer_id, v_total_amount
    FROM sales WHERE sale_id = p_sale_id;
    
    -- Update sale status
    UPDATE sales 
    SET status = 'refunded', notes = p_reason

    WHERE sale_id = p_sale_id;
    
    -- Restore inventory
    INSERT INTO inventory_transactions (product_id, transaction_type, quantity, reference_id, reference_type, notes)
    SELECT product_id, 'return', quantity, p_sale_id, 'refund', p_reason
    FROM sales_details WHERE sale_id = p_sale_id;
    
    -- Update product stock
    UPDATE products p
    JOIN sales_details sd ON p.product_id = sd.product_id
    SET p.stock = p.stock + sd.quantity
    WHERE sd.sale_id = p_sale_id;
    
    -- Update customer total spent
    UPDATE customers 
    SET total_spent = total_spent - v_total_amount
    WHERE customer_id = v_customer_id;
    
    COMMIT;
    
    SELECT 'Return processed successfully' AS message;
END //
DELIMITER ;

-- ================================================================
-- CUSTOMER PROCEDURES
-- ================================================================

-- Procedure: Get Customer Summary
DELIMITER //
CREATE PROCEDURE sp_customer_summary(IN p_customer_id INT)
BEGIN
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.phone,
        c.city,
        c.state,
        ct.tier_name,
        ct.discount_percentage AS current_discount,
        COUNT(s.sale_id) AS total_orders,
        COALESCE(SUM(s.total_amount), 0) AS total_spent,
        COALESCE(AVG(s.total_amount), 0) AS avg_order_value,
        MIN(s.sale_date) AS first_purchase,
        MAX(s.sale_date) AS last_purchase,
        DATEDIFF(CURRENT_DATE, MAX(s.sale_date)) AS days_since_last_purchase
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id, c.name, c.email, c.phone, c.city, c.state, ct.tier_name, ct.discount_percentage;
END //
DELIMITER ;

-- Procedure: Update Customer Tier Based on Spending
DELIMITER //
CREATE PROCEDURE sp_update_customer_tiers()
BEGIN
    -- Update all customers' tiers based on their total spending
    UPDATE customers c
    SET tier_id = (
        SELECT tier_id 
        FROM customer_tiers 
        WHERE c.total_spent >= min_purchases 
        ORDER BY min_purchases DESC 
        LIMIT 1
    );
    
    SELECT 'Customer tiers updated successfully' AS message,
           COUNT(*) AS customers_updated
    FROM customers;
END //
DELIMITER ;

-- ================================================================
-- REPORT PROCEDURES
-- ================================================================

-- Procedure: Generate Sales Report
DELIMITER //
CREATE PROCEDURE sp_sales_report(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_report_type ENUM('daily', 'weekly', 'monthly', 'quarterly')
)
BEGIN
    SELECT 
        CASE p_report_type
            WHEN 'daily' THEN DATE(sale_date)
            WHEN 'weekly' THEN CONCAT(YEAR(sale_date), '-W', LPAD(WEEK(sale_date), 2, '0'))
            WHEN 'monthly' THEN DATE_FORMAT(sale_date, '%Y-%m')
            WHEN 'quarterly' THEN CONCAT(YEAR(sale_date), '-Q', QUARTER(sale_date))
        END AS period,
        COUNT(DISTINCT sale_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(total_amount) AS total_revenue,
        AVG(total_amount) AS avg_order_value,
        SUM(discount_amount) AS total_discounts,
        SUM(tax_amount) AS total_tax
    FROM sales
    WHERE sale_date BETWEEN p_start_date AND p_end_date
      AND status = 'completed'
    GROUP BY period
    ORDER BY period;
END //
DELIMITER ;

-- Procedure: Generate Product Performance Report
DELIMITER //
CREATE PROCEDURE sp_product_performance_report(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_category_id INT
)
BEGIN
    SELECT 
        p.product_id,
        p.name AS product_name,
        cat.category_name,
        p.price,
        p.stock AS current_stock,
        COUNT(DISTINCT sd.sale_id) AS times_sold,
        SUM(sd.quantity) AS units_sold,
        SUM(sd.line_total) AS total_revenue,
        AVG(sd.unit_price) AS avg_selling_price,
        SUM(sd.line_total) - SUM(p.cost_price * sd.quantity) AS profit
    FROM products p
    LEFT JOIN categories cat ON p.category_id = cat.category_id
    LEFT JOIN sales_details sd ON p.product_id = sd.product_id
    LEFT JOIN sales s ON sd.sale_id = s.sale_id 
        AND s.sale_date BETWEEN p_start_date AND p_end_date
        AND s.status = 'completed'
    WHERE (p_category_id IS NULL OR p.category_id = p_category_id)
    GROUP BY p.product_id, p.name, cat.category_name, p.price, p.stock
    ORDER BY total_revenue DESC;
END //
DELIMITER ;

-- Procedure: Generate Inventory Alert Report
DELIMITER //
CREATE PROCEDURE sp_inventory_alerts()
BEGIN
    SELECT 
        p.product_id,
        p.name,
        p.sku,
        cat.category_name,
        p.stock AS current_stock,
        p.reorder_level,
        CASE 
            WHEN p.stock = 0 THEN 'OUT OF STOCK - URGENT'
            WHEN p.stock <= p.reorder_level THEN 'LOW STOCK - REORDER'
            ELSE 'OK'
        END AS alert_status,
        (p.reorder_level * 3) - p.stock AS suggested_order_qty,
        COALESCE(((p.reorder_level * 3) - p.stock) * p.cost_price, 0) AS estimated_cost
    FROM products p
    LEFT JOIN categories cat ON p.category_id = cat.category_id
    WHERE p.stock <= p.reorder_level
      AND p.is_active = TRUE
    ORDER BY 
        CASE WHEN p.stock = 0 THEN 0 ELSE 1 END,
        p.stock ASC;
END //
DELIMITER ;

-- ================================================================
-- INVENTORY PROCEDURES
-- ================================================================

-- Procedure: Transfer Stock Between Products (adjustment)
DELIMITER //
CREATE PROCEDURE sp_adjust_inventory(
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_adjustment_type ENUM('add', 'remove', 'set'),
    IN p_reason TEXT,
    IN p_employee_id INT
)
BEGIN
    DECLARE v_current_stock INT;
    DECLARE v_new_stock INT;
    DECLARE v_adjustment_qty INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current stock
    SELECT stock INTO v_current_stock 
    FROM products 
    WHERE product_id = p_product_id FOR UPDATE;
    
    -- Calculate new stock based on adjustment type
    CASE p_adjustment_type
        WHEN 'add' THEN 
            SET v_new_stock = v_current_stock + p_quantity;
            SET v_adjustment_qty = p_quantity;
        WHEN 'remove' THEN 
            SET v_new_stock = v_current_stock - p_quantity;
            SET v_adjustment_qty = -p_quantity;
        WHEN 'set' THEN 
            SET v_new_stock = p_quantity;
            SET v_adjustment_qty = p_quantity - v_current_stock;
    END CASE;
    
    -- Validate new stock is not negative
    IF v_new_stock < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot reduce stock below zero';
    END IF;
    
    -- Update product stock
    UPDATE products SET stock = v_new_stock WHERE product_id = p_product_id;
    
    -- Record inventory transaction
    INSERT INTO inventory_transactions (
        product_id, transaction_type, quantity, notes, created_by
    )
    VALUES (
        p_product_id, 'adjustment', v_adjustment_qty, p_reason, p_employee_id
    );
    
    COMMIT;
    
    SELECT 'Inventory adjusted successfully' AS message,
           v_current_stock AS previous_stock,
           v_new_stock AS new_stock;
END //
DELIMITER ;

-- ================================================================
-- VERIFICATION
-- ================================================================

DELIMITER ;

SELECT 'All stored procedures created successfully!' AS status;

-- List all procedures
SELECT 
    ROUTINE_NAME AS procedure_name,
    ROUTINE_TYPE AS type,
    CREATED AS created_at
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'retail_sales_advanced'
  AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
