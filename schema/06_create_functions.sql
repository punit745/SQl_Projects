-- ================================================================
-- USER-DEFINED FUNCTIONS SCRIPT
-- Creates all functions for reusable calculations
-- Run after: 02_create_tables.sql
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- PRODUCT FUNCTIONS
-- ================================================================

-- Function: Calculate Profit Margin for a Product
DELIMITER //
CREATE FUNCTION fn_profit_margin(p_product_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_cost DECIMAL(10,2);
    DECLARE v_margin DECIMAL(5,2);
    
    SELECT price, COALESCE(cost_price, 0) INTO v_price, v_cost
    FROM products
    WHERE product_id = p_product_id;
    
    IF v_price > 0 AND v_cost > 0 THEN
        SET v_margin = ((v_price - v_cost) / v_price) * 100;
    ELSE
        SET v_margin = 0;
    END IF;
    
    RETURN v_margin;
END //
DELIMITER ;

-- Function: Get Product Revenue
DELIMITER //
CREATE FUNCTION fn_product_revenue(p_product_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_revenue DECIMAL(12,2);
    
    SELECT COALESCE(SUM(sd.line_total), 0) INTO v_revenue
    FROM sales_details sd
    JOIN sales s ON sd.sale_id = s.sale_id
    WHERE sd.product_id = p_product_id
      AND s.status = 'completed';
    
    RETURN v_revenue;
END //
DELIMITER ;

-- Function: Check Stock Availability
DELIMITER //
CREATE FUNCTION fn_check_stock(p_product_id INT, p_quantity INT)
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_available INT;
    
    SELECT stock INTO v_available
    FROM products
    WHERE product_id = p_product_id;
    
    RETURN v_available >= p_quantity;
END //
DELIMITER ;

-- Function: Get Stock Status
DELIMITER //
CREATE FUNCTION fn_stock_status(p_product_id INT)
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_stock INT;
    DECLARE v_reorder_level INT;
    DECLARE v_status VARCHAR(20);
    
    SELECT stock, reorder_level INTO v_stock, v_reorder_level
    FROM products
    WHERE product_id = p_product_id;
    
    SET v_status = CASE 
        WHEN v_stock = 0 THEN 'Out of Stock'
        WHEN v_stock <= v_reorder_level THEN 'Low Stock'
        WHEN v_stock <= v_reorder_level * 2 THEN 'Adequate'
        ELSE 'Well Stocked'
    END;
    
    RETURN v_status;
END //
DELIMITER ;

-- ================================================================
-- CUSTOMER FUNCTIONS
-- ================================================================

-- Function: Get Customer Tier Name Based on Spending
DELIMITER //
CREATE FUNCTION fn_get_customer_tier(p_total_spent DECIMAL(12,2))
RETURNS VARCHAR(50)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_tier_name VARCHAR(50);
    
    SELECT tier_name INTO v_tier_name
    FROM customer_tiers
    WHERE p_total_spent >= min_purchases
    ORDER BY min_purchases DESC
    LIMIT 1;
    
    RETURN COALESCE(v_tier_name, 'Bronze');
END //
DELIMITER ;

-- Function: Calculate Customer Lifetime Value
DELIMITER //
CREATE FUNCTION fn_customer_ltv(p_customer_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ltv DECIMAL(12,2);
    
    SELECT COALESCE(SUM(total_amount), 0) INTO v_ltv
    FROM sales
    WHERE customer_id = p_customer_id
      AND status = 'completed';
    
    RETURN v_ltv;
END //
DELIMITER ;

-- Function: Calculate Customer Health Score (0-100)
DELIMITER //
CREATE FUNCTION fn_customer_health_score(p_customer_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_recency_score INT DEFAULT 0;
    DECLARE v_frequency_score INT DEFAULT 0;
    DECLARE v_monetary_score INT DEFAULT 0;
    DECLARE v_days_since_purchase INT;
    DECLARE v_order_count INT;
    DECLARE v_total_spent DECIMAL(12,2);
    
    SELECT 
        DATEDIFF(CURRENT_DATE, MAX(sale_date)),
        COUNT(*),
        COALESCE(SUM(total_amount), 0)
    INTO v_days_since_purchase, v_order_count, v_total_spent
    FROM sales 
    WHERE customer_id = p_customer_id
      AND status = 'completed';
    
    -- Recency Score (0-35 points) - lower days is better
    SET v_recency_score = CASE 
        WHEN v_days_since_purchase IS NULL THEN 0
        WHEN v_days_since_purchase <= 7 THEN 35
        WHEN v_days_since_purchase <= 14 THEN 30
        WHEN v_days_since_purchase <= 30 THEN 25
        WHEN v_days_since_purchase <= 60 THEN 15
        WHEN v_days_since_purchase <= 90 THEN 10
        ELSE 5
    END;
    
    -- Frequency Score (0-35 points)
    SET v_frequency_score = LEAST(v_order_count * 5, 35);
    
    -- Monetary Score (0-30 points)
    SET v_monetary_score = CASE 
        WHEN v_total_spent >= 200000 THEN 30
        WHEN v_total_spent >= 100000 THEN 25
        WHEN v_total_spent >= 50000 THEN 20
        WHEN v_total_spent >= 20000 THEN 15
        WHEN v_total_spent >= 10000 THEN 10
        WHEN v_total_spent > 0 THEN 5
        ELSE 0
    END;
    
    RETURN v_recency_score + v_frequency_score + v_monetary_score;
END //
DELIMITER ;

-- Function: Get Customer Segment
DELIMITER //
CREATE FUNCTION fn_customer_segment(p_customer_id INT)
RETURNS VARCHAR(30)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_health_score INT;
    DECLARE v_segment VARCHAR(30);
    
    SET v_health_score = fn_customer_health_score(p_customer_id);
    
    SET v_segment = CASE 
        WHEN v_health_score >= 80 THEN 'Champion'
        WHEN v_health_score >= 60 THEN 'Loyal'
        WHEN v_health_score >= 40 THEN 'Potential'
        WHEN v_health_score >= 20 THEN 'At Risk'
        WHEN v_health_score > 0 THEN 'Hibernating'
        ELSE 'Lost'
    END;
    
    RETURN v_segment;
END //
DELIMITER ;

-- Function: Days Since Last Purchase
DELIMITER //
CREATE FUNCTION fn_days_since_purchase(p_customer_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    
    SELECT DATEDIFF(CURRENT_DATE, MAX(sale_date)) INTO v_days
    FROM sales
    WHERE customer_id = p_customer_id
      AND status = 'completed';
    
    RETURN COALESCE(v_days, -1); -- -1 indicates never purchased
END //
DELIMITER ;

-- ================================================================
-- SALES FUNCTIONS
-- ================================================================

-- Function: Calculate Tax Amount
DELIMITER //
CREATE FUNCTION fn_calculate_tax(p_amount DECIMAL(12,2), p_tax_rate DECIMAL(5,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(p_amount * p_tax_rate / 100, 2);
END //
DELIMITER ;

-- Function: Calculate Discount Amount
DELIMITER //
CREATE FUNCTION fn_calculate_discount(p_amount DECIMAL(12,2), p_discount_pct DECIMAL(5,2))
RETURNS DECIMAL(12,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN ROUND(p_amount * p_discount_pct / 100, 2);
END //
DELIMITER ;

-- Function: Get Order Total
DELIMITER //
CREATE FUNCTION fn_order_total(p_sale_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    
    SELECT total_amount INTO v_total
    FROM sales
    WHERE sale_id = p_sale_id;
    
    RETURN COALESCE(v_total, 0);
END //
DELIMITER ;

-- ================================================================
-- DATE/TIME FUNCTIONS
-- ================================================================

-- Function: Get Fiscal Quarter
DELIMITER //
CREATE FUNCTION fn_fiscal_quarter(p_date DATE)
RETURNS VARCHAR(10)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT('Q', QUARTER(p_date), '-', YEAR(p_date));
END //
DELIMITER ;

-- Function: Get Week Number with Year
DELIMITER //
CREATE FUNCTION fn_week_year(p_date DATE)
RETURNS VARCHAR(10)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT(YEAR(p_date), '-W', LPAD(WEEK(p_date), 2, '0'));
END //
DELIMITER ;

-- Function: Check if Date is Weekend
DELIMITER //
CREATE FUNCTION fn_is_weekend(p_date DATE)
RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN DAYOFWEEK(p_date) IN (1, 7); -- Sunday = 1, Saturday = 7
END //
DELIMITER ;

-- ================================================================
-- UTILITY FUNCTIONS
-- ================================================================

-- Function: Mask Email Address
DELIMITER //
CREATE FUNCTION fn_mask_email(p_email VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_at_pos INT;
    DECLARE v_username VARCHAR(100);
    DECLARE v_domain VARCHAR(100);
    
    SET v_at_pos = LOCATE('@', p_email);
    
    IF v_at_pos = 0 THEN
        RETURN p_email;
    END IF;
    
    SET v_username = LEFT(p_email, v_at_pos - 1);
    SET v_domain = SUBSTRING(p_email, v_at_pos);
    
    -- Mask middle characters of username
    IF LENGTH(v_username) <= 2 THEN
        RETURN CONCAT(LEFT(v_username, 1), '*', v_domain);
    ELSE
        RETURN CONCAT(
            LEFT(v_username, 1),
            REPEAT('*', LENGTH(v_username) - 2),
            RIGHT(v_username, 1),
            v_domain
        );
    END IF;
END //
DELIMITER ;

-- Function: Mask Phone Number
DELIMITER //
CREATE FUNCTION fn_mask_phone(p_phone VARCHAR(20))
RETURNS VARCHAR(20)
DETERMINISTIC
NO SQL
BEGIN
    IF LENGTH(p_phone) < 4 THEN
        RETURN REPEAT('*', LENGTH(p_phone));
    END IF;
    
    RETURN CONCAT(
        REPEAT('*', LENGTH(p_phone) - 4),
        RIGHT(p_phone, 4)
    );
END //
DELIMITER ;

-- Function: Format Currency (Indian Rupees)
DELIMITER //
CREATE FUNCTION fn_format_inr(p_amount DECIMAL(15,2))
RETURNS VARCHAR(30)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT('₹ ', FORMAT(p_amount, 2, 'en_IN'));
END //
DELIMITER ;

-- ================================================================
-- VERIFICATION
-- ================================================================

DELIMITER ;

SELECT 'All functions created successfully!' AS status;

-- List all functions
SELECT 
    ROUTINE_NAME AS function_name,
    DATA_TYPE AS return_type,
    CREATED AS created_at
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'retail_sales_advanced'
  AND ROUTINE_TYPE = 'FUNCTION'
ORDER BY ROUTINE_NAME;
