-- ================================================================
-- SECURITY AND AUDIT LOGGING
-- User management, privileges, audit trails, data masking
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: USER AND ROLE MANAGEMENT
-- ================================================================

-- Create database users with different access levels

-- Read-only analyst user
CREATE USER IF NOT EXISTS 'analyst'@'localhost' 
IDENTIFIED BY 'Analyst@SecurePass123';

-- Application user (read + write on specific tables)
CREATE USER IF NOT EXISTS 'app_user'@'localhost' 
IDENTIFIED BY 'App@SecurePass456';

-- Admin user (full access)
CREATE USER IF NOT EXISTS 'db_admin'@'localhost' 
IDENTIFIED BY 'Admin@SecurePass789';

-- Report generator user
CREATE USER IF NOT EXISTS 'report_user'@'localhost' 
IDENTIFIED BY 'Report@SecurePass101';

-- ================================================================
-- SECTION 2: PRIVILEGE MANAGEMENT
-- ================================================================

-- Grant read-only access to analyst
GRANT SELECT ON retail_sales_advanced.* TO 'analyst'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_sales_summary TO 'analyst'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_product_performance TO 'analyst'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_customer_analytics TO 'analyst'@'localhost';

-- Grant app user access (no DELETE on critical tables)
GRANT SELECT, INSERT, UPDATE ON retail_sales_advanced.sales TO 'app_user'@'localhost';
GRANT SELECT, INSERT, UPDATE ON retail_sales_advanced.sales_details TO 'app_user'@'localhost';
GRANT SELECT, INSERT, UPDATE ON retail_sales_advanced.customers TO 'app_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.products TO 'app_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.categories TO 'app_user'@'localhost';
GRANT EXECUTE ON PROCEDURE retail_sales_advanced.sp_add_sale TO 'app_user'@'localhost';
GRANT EXECUTE ON PROCEDURE retail_sales_advanced.sp_customer_summary TO 'app_user'@'localhost';

-- Grant full access to admin
GRANT ALL PRIVILEGES ON retail_sales_advanced.* TO 'db_admin'@'localhost';

-- Grant report user access to views only
GRANT SELECT ON retail_sales_advanced.vw_sales_summary TO 'report_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_product_performance TO 'report_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_customer_analytics TO 'report_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_daily_sales TO 'report_user'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_monthly_sales TO 'report_user'@'localhost';
GRANT EXECUTE ON PROCEDURE retail_sales_advanced.sp_sales_report TO 'report_user'@'localhost';

-- Apply privilege changes
FLUSH PRIVILEGES;

-- ================================================================
-- SECTION 3: VIEW USER PRIVILEGES
-- ================================================================

-- Check grants for a specific user
SHOW GRANTS FOR 'analyst'@'localhost';
SHOW GRANTS FOR 'app_user'@'localhost';

-- Check all users
SELECT 
    User, 
    Host, 
    account_locked,
    password_expired
FROM mysql.user
WHERE User IN ('analyst', 'app_user', 'db_admin', 'report_user');

-- ================================================================
-- SECTION 4: AUDIT TRAIL TABLES
-- ================================================================

-- The audit_log table was created in 02_create_tables.sql
-- Here are additional audit-related queries

-- Create data access log
CREATE TABLE IF NOT EXISTS data_access_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100),
    table_accessed VARCHAR(100),
    columns_accessed TEXT,
    query_type ENUM('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'OTHER'),
    row_count INT,
    access_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    session_id VARCHAR(100)
) ENGINE=InnoDB;

-- Create login audit table
CREATE TABLE IF NOT EXISTS login_audit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    login_status ENUM('SUCCESS', 'FAILED', 'LOCKED'),
    failure_reason VARCHAR(255)
) ENGINE=InnoDB;

-- Create sensitive data access log
CREATE TABLE IF NOT EXISTS sensitive_data_access (
    access_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100),
    data_type VARCHAR(50),
    record_id INT,
    access_reason TEXT,
    access_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    approved_by VARCHAR(100)
) ENGINE=InnoDB;

-- ================================================================
-- SECTION 5: AUDIT TRIGGERS
-- ================================================================

-- Trigger to log customer data access (sensitive data)
DELIMITER //
CREATE TRIGGER trg_audit_customer_access
BEFORE UPDATE ON customers
FOR EACH ROW
BEGIN
    -- Log access to sensitive fields
    IF OLD.email != NEW.email OR OLD.phone != NEW.phone THEN
        INSERT INTO sensitive_data_access (
            user_name, 
            data_type, 
            record_id, 
            access_reason
        )
        VALUES (
            CURRENT_USER(), 
            'CUSTOMER_PII', 
            NEW.customer_id,
            'Email or phone update'
        );
    END IF;
END //
DELIMITER ;

-- Comprehensive audit trigger for sales
DELIMITER //
CREATE TRIGGER trg_comprehensive_sales_audit
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
            'customer_id', OLD.customer_id,
            'total_amount', OLD.total_amount,
            'discount_amount', OLD.discount_amount,
            'status', OLD.status,
            'updated_at', OLD.updated_at
        ),
        JSON_OBJECT(
            'customer_id', NEW.customer_id,
            'total_amount', NEW.total_amount,
            'discount_amount', NEW.discount_amount,
            'status', NEW.status,
            'updated_at', NEW.updated_at
        ),
        CURRENT_USER()
    );
END //
DELIMITER ;

-- ================================================================
-- SECTION 6: DATA MASKING VIEWS
-- ================================================================

-- Create view with masked customer data for non-privileged users
CREATE OR REPLACE VIEW vw_customers_masked AS
SELECT 
    customer_id,
    CONCAT(LEFT(name, 1), '***', RIGHT(name, 1)) AS name_masked,
    CONCAT(
        LEFT(email, 2), 
        '***', 
        SUBSTRING(email, LOCATE('@', email))
    ) AS email_masked,
    CONCAT('******', RIGHT(phone, 4)) AS phone_masked,
    city,
    state,
    tier_id,
    registration_date,
    total_spent
FROM customers;

-- Create view with masked sales data
CREATE OR REPLACE VIEW vw_sales_masked AS
SELECT 
    sale_id,
    s.customer_id,
    CONCAT(LEFT(c.name, 1), '***') AS customer_name_masked,
    DATE(sale_date) AS sale_date,
    -- Round amounts to hide exact figures
    ROUND(total_amount, -3) AS total_amount_rounded,
    status
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id;

-- Grant access to masked views for analysts
GRANT SELECT ON retail_sales_advanced.vw_customers_masked TO 'analyst'@'localhost';
GRANT SELECT ON retail_sales_advanced.vw_sales_masked TO 'analyst'@'localhost';

-- ================================================================
-- SECTION 7: DATA MASKING FUNCTIONS
-- ================================================================

-- The masking functions were created in 06_create_functions.sql
-- Here are additional masking utilities

-- Mask credit card number
DELIMITER //
CREATE FUNCTION fn_mask_credit_card(p_card_number VARCHAR(20))
RETURNS VARCHAR(20)
DETERMINISTIC
NO SQL
BEGIN
    IF LENGTH(p_card_number) < 4 THEN
        RETURN REPEAT('*', LENGTH(p_card_number));
    END IF;
    
    RETURN CONCAT(
        REPEAT('*', LENGTH(p_card_number) - 4),
        RIGHT(p_card_number, 4)
    );
END //
DELIMITER ;

-- Mask name (show first and last character)
DELIMITER //
CREATE FUNCTION fn_mask_name(p_name VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
NO SQL
BEGIN
    IF LENGTH(p_name) <= 2 THEN
        RETURN REPEAT('*', LENGTH(p_name));
    END IF;
    
    RETURN CONCAT(
        LEFT(p_name, 1),
        REPEAT('*', LENGTH(p_name) - 2),
        RIGHT(p_name, 1)
    );
END //
DELIMITER ;

-- ================================================================
-- SECTION 8: SECURITY POLICIES (Row-Level Security Simulation)
-- ================================================================

-- MySQL doesn't have native RLS, but we can simulate with views

-- Create a context table for user permissions
CREATE TABLE IF NOT EXISTS user_data_permissions (
    permission_id INT PRIMARY KEY AUTO_INCREMENT,
    user_name VARCHAR(100),
    allowed_cities JSON,
    allowed_tiers JSON,
    can_view_pii BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample permissions
INSERT INTO user_data_permissions (user_name, allowed_cities, allowed_tiers, can_view_pii)
VALUES 
    ('analyst', '["Mumbai", "Delhi", "Bangalore"]', '[1, 2, 3, 4]', FALSE),
    ('regional_manager_west', '["Mumbai", "Pune", "Ahmedabad"]', '[1, 2, 3, 4]', TRUE);

-- Create a stored procedure that returns filtered data based on user
DELIMITER //
CREATE PROCEDURE sp_get_customers_for_user()
BEGIN
    DECLARE v_allowed_cities JSON;
    DECLARE v_can_view_pii BOOLEAN;
    
    -- Get user permissions
    SELECT allowed_cities, can_view_pii INTO v_allowed_cities, v_can_view_pii
    FROM user_data_permissions
    WHERE user_name = CURRENT_USER();
    
    IF v_allowed_cities IS NULL THEN
        -- No permissions found, return empty
        SELECT 'Access denied' AS error;
    ELSEIF v_can_view_pii THEN
        -- Full access to allowed cities
        SELECT c.*
        FROM customers c
        WHERE JSON_CONTAINS(v_allowed_cities, JSON_QUOTE(c.city));
    ELSE
        -- Masked access
        SELECT 
            customer_id,
            fn_mask_name(name) AS name,
            fn_mask_email(email) AS email,
            fn_mask_phone(phone) AS phone,
            city,
            state,
            tier_id,
            total_spent
        FROM customers
        WHERE JSON_CONTAINS(v_allowed_cities, JSON_QUOTE(city));
    END IF;
END //
DELIMITER ;

-- ================================================================
-- SECTION 9: PASSWORD POLICIES
-- ================================================================

-- View current password policy
SHOW VARIABLES LIKE 'validate_password%';

-- Set password policy (requires root)
-- SET GLOBAL validate_password.policy = MEDIUM;
-- SET GLOBAL validate_password.length = 12;
-- SET GLOBAL validate_password.mixed_case_count = 1;
-- SET GLOBAL validate_password.number_count = 1;
-- SET GLOBAL validate_password.special_char_count = 1;

-- Expire a user's password
-- ALTER USER 'analyst'@'localhost' PASSWORD EXPIRE;

-- Set password expiration policy
-- ALTER USER 'app_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;

-- Lock an account
-- ALTER USER 'analyst'@'localhost' ACCOUNT LOCK;

-- Unlock an account
-- ALTER USER 'analyst'@'localhost' ACCOUNT UNLOCK;

-- ================================================================
-- SECTION 10: AUDIT QUERIES
-- ================================================================

-- View recent audit entries
SELECT 
    log_id,
    table_name,
    action_type,
    record_id,
    JSON_PRETTY(old_values) AS old_values,
    JSON_PRETTY(new_values) AS new_values,
    changed_by,
    changed_at
FROM audit_log
ORDER BY changed_at DESC
LIMIT 20;

-- Audit summary by table and action
SELECT 
    table_name,
    action_type,
    COUNT(*) AS change_count,
    MIN(changed_at) AS first_change,
    MAX(changed_at) AS last_change
FROM audit_log
GROUP BY table_name, action_type
ORDER BY table_name, action_type;

-- Find suspicious activity (multiple changes by same user in short time)
SELECT 
    changed_by,
    COUNT(*) AS changes_in_hour,
    MIN(changed_at) AS first_change,
    MAX(changed_at) AS last_change
FROM audit_log
WHERE changed_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY changed_by
HAVING COUNT(*) > 10
ORDER BY changes_in_hour DESC;

-- Track price changes
SELECT 
    record_id AS product_id,
    JSON_EXTRACT(old_values, '$.price') AS old_price,
    JSON_EXTRACT(new_values, '$.price') AS new_price,
    changed_by,
    changed_at
FROM audit_log
WHERE table_name = 'products'
  AND action_type = 'UPDATE'
  AND JSON_EXTRACT(old_values, '$.price') != JSON_EXTRACT(new_values, '$.price')
ORDER BY changed_at DESC;

-- ================================================================
-- SECTION 11: COMPLIANCE HELPERS
-- ================================================================

-- Stored procedure for GDPR data export
DELIMITER //
CREATE PROCEDURE sp_export_customer_data(IN p_customer_id INT)
BEGIN
    -- Customer basic info
    SELECT 'CUSTOMER_INFO' AS data_type, c.* 
    FROM customers c WHERE customer_id = p_customer_id;
    
    -- Customer orders
    SELECT 'ORDER_HISTORY' AS data_type, s.* 
    FROM sales s WHERE customer_id = p_customer_id;
    
    -- Order details
    SELECT 'ORDER_DETAILS' AS data_type, sd.* 
    FROM sales_details sd 
    JOIN sales s ON sd.sale_id = s.sale_id 
    WHERE s.customer_id = p_customer_id;
    
    -- Activity logs
    SELECT 'ACTIVITY_LOG' AS data_type, cal.* 
    FROM customer_activity_log cal 
    WHERE customer_id = p_customer_id;
    
    -- Log the data export
    INSERT INTO sensitive_data_access (user_name, data_type, record_id, access_reason)
    VALUES (CURRENT_USER(), 'GDPR_EXPORT', p_customer_id, 'Customer data export request');
END //
DELIMITER ;

-- Stored procedure for GDPR data deletion (right to be forgotten)
DELIMITER //
CREATE PROCEDURE sp_delete_customer_data(
    IN p_customer_id INT,
    IN p_deletion_reason TEXT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Log the deletion request
    INSERT INTO sensitive_data_access (user_name, data_type, record_id, access_reason)
    VALUES (CURRENT_USER(), 'GDPR_DELETION', p_customer_id, p_deletion_reason);
    
    -- Anonymize customer data instead of deleting (for audit trail)
    UPDATE customers
    SET 
        name = CONCAT('DELETED_', customer_id),
        email = CONCAT('deleted_', customer_id, '@anonymized.local'),
        phone = NULL,
        address = NULL,
        is_active = FALSE,
        preferences = NULL
    WHERE customer_id = p_customer_id;
    
    -- Delete activity logs
    DELETE FROM customer_activity_log WHERE customer_id = p_customer_id;
    
    COMMIT;
    
    SELECT 'Customer data anonymized successfully' AS status;
END //
DELIMITER ;

-- ================================================================
-- SECTION 12: SECURITY BEST PRACTICES CHECKLIST
-- ================================================================

/*
Security Best Practices for MySQL:

1. User Management
   ✓ Use strong passwords
   ✓ Create separate users for different purposes
   ✓ Apply principle of least privilege
   ✓ Regularly review and revoke unnecessary privileges

2. Authentication
   ✓ Use secure authentication plugins
   ✓ Enable password expiration
   ✓ Implement account lockout policies

3. Network Security
   ✓ Use SSL/TLS for connections
   ✓ Restrict access by IP/host
   ✓ Use firewall rules

4. Data Protection
   ✓ Encrypt sensitive data at rest
   ✓ Use SSL for data in transit
   ✓ Implement data masking for non-privileged users

5. Auditing
   ✓ Enable audit logging
   ✓ Monitor for suspicious activity
   ✓ Retain logs for compliance

6. Backup Security
   ✓ Encrypt backups
   ✓ Test restoration regularly
   ✓ Store backups securely off-site
*/

-- ================================================================
-- END OF SECURITY AND AUDIT
-- ================================================================
