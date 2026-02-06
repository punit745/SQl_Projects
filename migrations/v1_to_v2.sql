-- ================================================================
-- DATABASE MIGRATION SCRIPTS
-- Version-controlled schema changes (MySQL 5.7+ compatible)
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: MIGRATION TRACKING TABLE
-- ================================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
    migration_id INT AUTO_INCREMENT PRIMARY KEY,
    version VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100),
    execution_time_ms INT,
    status ENUM('pending', 'applied', 'failed', 'rolled_back') DEFAULT 'pending'
);

-- ================================================================
-- SECTION 2: MIGRATION HELPER PROCEDURES
-- ================================================================

DELIMITER //

-- Check if migration was applied
DROP FUNCTION IF EXISTS fn_migration_applied //
CREATE FUNCTION fn_migration_applied(p_version VARCHAR(50))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM schema_migrations 
    WHERE version = p_version AND status = 'applied';
    RETURN v_count > 0;
END //

-- Helper: Check if column exists
DROP FUNCTION IF EXISTS fn_column_exists //
CREATE FUNCTION fn_column_exists(p_table VARCHAR(100), p_column VARCHAR(100))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'retail_sales_advanced' 
      AND TABLE_NAME = p_table 
      AND COLUMN_NAME = p_column;
    RETURN v_count > 0;
END //

-- Register migration start
DROP PROCEDURE IF EXISTS sp_start_migration //
CREATE PROCEDURE sp_start_migration(
    IN p_version VARCHAR(50),
    IN p_name VARCHAR(200)
)
BEGIN
    IF fn_migration_applied(p_version) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Migration already applied';
    END IF;
    
    INSERT INTO schema_migrations (version, name, applied_by, status)
    VALUES (p_version, p_name, CURRENT_USER(), 'pending');
    
    SELECT CONCAT('Starting migration: ', p_version, ' - ', p_name) AS status;
END //

-- Complete migration
DROP PROCEDURE IF EXISTS sp_complete_migration //
CREATE PROCEDURE sp_complete_migration(
    IN p_version VARCHAR(50),
    IN p_execution_time_ms INT
)
BEGIN
    UPDATE schema_migrations
    SET status = 'applied',
        execution_time_ms = p_execution_time_ms
    WHERE version = p_version;
    
    SELECT CONCAT('Migration completed: ', p_version) AS status;
END //

-- Fail migration
DROP PROCEDURE IF EXISTS sp_fail_migration //
CREATE PROCEDURE sp_fail_migration(
    IN p_version VARCHAR(50),
    IN p_error_message TEXT
)
BEGIN
    UPDATE schema_migrations
    SET status = 'failed'
    WHERE version = p_version;
    
    SELECT CONCAT('Migration failed: ', p_version, ' - ', p_error_message) AS status;
END //

DELIMITER ;

-- ================================================================
-- MIGRATION V001: Add customer preferences column
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS migration_v001_customer_preferences //
CREATE PROCEDURE migration_v001_customer_preferences()
BEGIN
    DECLARE v_start_time DATETIME(6);
    DECLARE v_version VARCHAR(50) DEFAULT 'v001';
    DECLARE v_name VARCHAR(200) DEFAULT 'Add customer preferences column';
    
    IF fn_migration_applied(v_version) THEN
        SELECT CONCAT('Migration ', v_version, ' already applied') AS status;
    ELSE
        CALL sp_start_migration(v_version, v_name);
        SET v_start_time = NOW(6);
        
        -- Add preferences JSON column if not exists
        IF NOT fn_column_exists('customers', 'preferences') THEN
            ALTER TABLE customers ADD COLUMN preferences JSON DEFAULT NULL;
        END IF;
        
        CALL sp_complete_migration(v_version, TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- MIGRATION V002: Create product reviews table
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS migration_v002_product_reviews //
CREATE PROCEDURE migration_v002_product_reviews()
BEGIN
    DECLARE v_start_time DATETIME(6);
    DECLARE v_version VARCHAR(50) DEFAULT 'v002';
    DECLARE v_name VARCHAR(200) DEFAULT 'Create product reviews table';
    
    IF fn_migration_applied(v_version) THEN
        SELECT CONCAT('Migration ', v_version, ' already applied') AS status;
    ELSE
        CALL sp_start_migration(v_version, v_name);
        SET v_start_time = NOW(6);
        
        CREATE TABLE IF NOT EXISTS product_reviews (
            review_id INT AUTO_INCREMENT PRIMARY KEY,
            product_id INT NOT NULL,
            customer_id INT NOT NULL,
            rating TINYINT NOT NULL,
            title VARCHAR(200),
            content TEXT,
            is_verified_purchase BOOLEAN DEFAULT FALSE,
            helpful_votes INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_product_rating (product_id, rating),
            INDEX idx_customer_reviews (customer_id)
        );
        
        CALL sp_complete_migration(v_version, TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- MIGRATION V003: Add product rating aggregate
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS migration_v003_product_rating //
CREATE PROCEDURE migration_v003_product_rating()
BEGIN
    DECLARE v_start_time DATETIME(6);
    DECLARE v_version VARCHAR(50) DEFAULT 'v003';
    DECLARE v_name VARCHAR(200) DEFAULT 'Add average rating to products';
    
    IF fn_migration_applied(v_version) THEN
        SELECT CONCAT('Migration ', v_version, ' already applied') AS status;
    ELSE
        CALL sp_start_migration(v_version, v_name);
        SET v_start_time = NOW(6);
        
        -- Add rating columns to products
        IF NOT fn_column_exists('products', 'avg_rating') THEN
            ALTER TABLE products ADD COLUMN avg_rating DECIMAL(3,2) DEFAULT NULL;
        END IF;
        
        IF NOT fn_column_exists('products', 'review_count') THEN
            ALTER TABLE products ADD COLUMN review_count INT DEFAULT 0;
        END IF;
        
        CALL sp_complete_migration(v_version, TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- MIGRATION V004: Add shipping information
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS migration_v004_shipping //
CREATE PROCEDURE migration_v004_shipping()
BEGIN
    DECLARE v_start_time DATETIME(6);
    DECLARE v_version VARCHAR(50) DEFAULT 'v004';
    DECLARE v_name VARCHAR(200) DEFAULT 'Add shipping information tables';
    
    IF fn_migration_applied(v_version) THEN
        SELECT CONCAT('Migration ', v_version, ' already applied') AS status;
    ELSE
        CALL sp_start_migration(v_version, v_name);
        SET v_start_time = NOW(6);
        
        -- Shipping carriers
        CREATE TABLE IF NOT EXISTS shipping_carriers (
            carrier_id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            code VARCHAR(20) UNIQUE,
            tracking_url_template VARCHAR(500),
            is_active BOOLEAN DEFAULT TRUE
        );
        
        -- Shipments table
        CREATE TABLE IF NOT EXISTS shipments (
            shipment_id INT AUTO_INCREMENT PRIMARY KEY,
            sale_id INT NOT NULL,
            carrier_id INT,
            tracking_number VARCHAR(100),
            status ENUM('pending', 'shipped', 'in_transit', 'delivered', 'returned') DEFAULT 'pending',
            shipped_at DATETIME,
            delivered_at DATETIME,
            shipping_address TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_tracking (tracking_number),
            INDEX idx_status (status)
        );
        
        -- Add shipping columns to sales
        IF NOT fn_column_exists('sales', 'shipping_address_id') THEN
            ALTER TABLE sales ADD COLUMN shipping_address_id INT;
        END IF;
        
        IF NOT fn_column_exists('sales', 'shipping_cost') THEN
            ALTER TABLE sales ADD COLUMN shipping_cost DECIMAL(10,2) DEFAULT 0;
        END IF;
        
        -- Insert default carriers
        INSERT IGNORE INTO shipping_carriers (name, code, tracking_url_template) VALUES
        ('BlueDart', 'BLUEDART', 'https://www.bluedart.com/tracking?awb={tracking}'),
        ('Delhivery', 'DELHIVERY', 'https://www.delhivery.com/track/package/{tracking}'),
        ('FedEx', 'FEDEX', 'https://www.fedex.com/fedextrack/?trknbr={tracking}'),
        ('DTDC', 'DTDC', 'https://www.dtdc.in/trace.asp?stession={tracking}');
        
        CALL sp_complete_migration(v_version, TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- MIGRATION V005: Add promotional codes
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS migration_v005_promo_codes //
CREATE PROCEDURE migration_v005_promo_codes()
BEGIN
    DECLARE v_start_time DATETIME(6);
    DECLARE v_version VARCHAR(50) DEFAULT 'v005';
    DECLARE v_name VARCHAR(200) DEFAULT 'Add promotional codes';
    
    IF fn_migration_applied(v_version) THEN
        SELECT CONCAT('Migration ', v_version, ' already applied') AS status;
    ELSE
        CALL sp_start_migration(v_version, v_name);
        SET v_start_time = NOW(6);
        
        -- Promo codes table
        CREATE TABLE IF NOT EXISTS promo_codes (
            promo_id INT AUTO_INCREMENT PRIMARY KEY,
            code VARCHAR(50) NOT NULL UNIQUE,
            description TEXT,
            discount_type ENUM('percentage', 'fixed') NOT NULL,
            discount_value DECIMAL(10,2) NOT NULL,
            min_order_value DECIMAL(10,2) DEFAULT 0,
            max_discount DECIMAL(10,2),
            usage_limit INT,
            used_count INT DEFAULT 0,
            valid_from DATETIME,
            valid_until DATETIME,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Promo usage log
        CREATE TABLE IF NOT EXISTS promo_usage (
            usage_id INT AUTO_INCREMENT PRIMARY KEY,
            promo_id INT NOT NULL,
            sale_id INT NOT NULL,
            customer_id INT NOT NULL,
            discount_applied DECIMAL(10,2),
            used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Add promo_id to sales
        IF NOT fn_column_exists('sales', 'promo_id') THEN
            ALTER TABLE sales ADD COLUMN promo_id INT;
        END IF;
        
        CALL sp_complete_migration(v_version, TIMESTAMPDIFF(MICROSECOND, v_start_time, NOW(6)) / 1000);
    END IF;
END //
DELIMITER ;

-- ================================================================
-- APPLY ALL MIGRATIONS
-- ================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS apply_all_migrations //
CREATE PROCEDURE apply_all_migrations()
BEGIN
    SELECT 'Applying all pending migrations...' AS status;
    
    CALL migration_v001_customer_preferences();
    CALL migration_v002_product_reviews();
    CALL migration_v003_product_rating();
    CALL migration_v004_shipping();
    CALL migration_v005_promo_codes();
    
    SELECT * FROM schema_migrations ORDER BY version;
END //
DELIMITER ;

-- ================================================================
-- VIEW MIGRATION STATUS
-- ================================================================

CREATE OR REPLACE VIEW vw_migration_status AS
SELECT 
    version,
    name,
    status,
    applied_at,
    applied_by,
    CONCAT(execution_time_ms, 'ms') AS execution_time
FROM schema_migrations
ORDER BY version;

-- ================================================================
-- USAGE
-- ================================================================

/*
-- Apply all migrations
CALL apply_all_migrations();

-- Check migration status
SELECT * FROM vw_migration_status;
*/

SELECT 'Migration scripts loaded successfully!' AS status;
