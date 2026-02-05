-- ================================================================
-- ETL PROCEDURES FOR DATA WAREHOUSE
-- Extract, Transform, Load processes
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: ETL STATE TRACKING
-- ================================================================

-- ETL job tracking table
CREATE TABLE IF NOT EXISTS etl_job_log (
    job_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    status ENUM('running', 'completed', 'failed') DEFAULT 'running',
    rows_processed INT DEFAULT 0,
    rows_inserted INT DEFAULT 0,
    rows_updated INT DEFAULT 0,
    rows_deleted INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ETL checkpoint table (for incremental loads)
CREATE TABLE IF NOT EXISTS etl_checkpoint (
    checkpoint_id INT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(100) NOT NULL UNIQUE,
    last_extracted_id BIGINT,
    last_extracted_timestamp DATETIME,
    last_run_time DATETIME,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ================================================================
-- SECTION 2: ETL UTILITY PROCEDURES
-- ================================================================

DELIMITER //

-- Start ETL job
CREATE PROCEDURE sp_etl_start_job(
    IN p_job_name VARCHAR(100),
    OUT p_job_id BIGINT
)
BEGIN
    INSERT INTO etl_job_log (job_name, start_time, status)
    VALUES (p_job_name, NOW(), 'running');
    
    SET p_job_id = LAST_INSERT_ID();
END //

-- Complete ETL job
CREATE PROCEDURE sp_etl_complete_job(
    IN p_job_id BIGINT,
    IN p_rows_processed INT,
    IN p_rows_inserted INT,
    IN p_rows_updated INT,
    IN p_rows_deleted INT
)
BEGIN
    UPDATE etl_job_log
    SET 
        end_time = NOW(),
        status = 'completed',
        rows_processed = p_rows_processed,
        rows_inserted = p_rows_inserted,
        rows_updated = p_rows_updated,
        rows_deleted = p_rows_deleted
    WHERE job_id = p_job_id;
END //

-- Fail ETL job
CREATE PROCEDURE sp_etl_fail_job(
    IN p_job_id BIGINT,
    IN p_error_message TEXT
)
BEGIN
    UPDATE etl_job_log
    SET 
        end_time = NOW(),
        status = 'failed',
        error_message = p_error_message
    WHERE job_id = p_job_id;
END //

-- Get last checkpoint
CREATE FUNCTION fn_get_checkpoint(p_source_table VARCHAR(100))
RETURNS DATETIME
DETERMINISTIC
BEGIN
    DECLARE v_checkpoint DATETIME;
    
    SELECT last_extracted_timestamp INTO v_checkpoint
    FROM etl_checkpoint
    WHERE source_table = p_source_table;
    
    RETURN COALESCE(v_checkpoint, '1900-01-01');
END //

-- Update checkpoint
CREATE PROCEDURE sp_update_checkpoint(
    IN p_source_table VARCHAR(100),
    IN p_last_id BIGINT,
    IN p_last_timestamp DATETIME
)
BEGIN
    INSERT INTO etl_checkpoint (source_table, last_extracted_id, last_extracted_timestamp, last_run_time)
    VALUES (p_source_table, p_last_id, p_last_timestamp, NOW())
    ON DUPLICATE KEY UPDATE
        last_extracted_id = p_last_id,
        last_extracted_timestamp = p_last_timestamp,
        last_run_time = NOW();
END //

DELIMITER ;

-- ================================================================
-- SECTION 3: DIMENSION LOADING PROCEDURES
-- ================================================================

DELIMITER //

-- Full load for dim_customer
CREATE PROCEDURE sp_etl_load_dim_customer_full()
BEGIN
    DECLARE v_job_id BIGINT;
    DECLARE v_rows_inserted INT DEFAULT 0;
    DECLARE v_rows_updated INT DEFAULT 0;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        CALL sp_etl_fail_job(v_job_id, v_error_msg);
        RESIGNAL;
    END;
    
    -- Start job
    CALL sp_etl_start_job('load_dim_customer_full', v_job_id);
    
    -- Expire all current records
    UPDATE dim_customer
    SET expiry_date = CURRENT_DATE - INTERVAL 1 DAY,
        is_current = FALSE
    WHERE is_current = TRUE;
    
    SET v_rows_updated = ROW_COUNT();
    
    -- Insert fresh data
    INSERT INTO dim_customer (
        customer_id, name, email, phone, city, state, zip_code,
        tier_name, segment, effective_date, expiry_date, is_current
    )
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.phone,
        c.city,
        c.state,
        c.zip_code,
        COALESCE(ct.tier_name, 'Unknown'),
        CASE 
            WHEN c.total_spent >= 100000 THEN 'VIP'
            WHEN c.total_spent >= 50000 THEN 'Premium'
            WHEN c.total_spent >= 10000 THEN 'Regular'
            ELSE 'New'
        END,
        CURRENT_DATE,
        '9999-12-31',
        TRUE
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id;
    
    SET v_rows_inserted = ROW_COUNT();
    
    -- Complete job
    CALL sp_etl_complete_job(v_job_id, v_rows_inserted, v_rows_inserted, v_rows_updated, 0);
    
    SELECT 'dim_customer loaded successfully' AS result,
           v_rows_inserted AS rows_inserted;
END //

-- Incremental load for dim_customer (SCD Type 2)
CREATE PROCEDURE sp_etl_load_dim_customer_incremental()
BEGIN
    DECLARE v_job_id BIGINT;
    DECLARE v_rows_processed INT DEFAULT 0;
    DECLARE v_rows_inserted INT DEFAULT 0;
    DECLARE v_rows_updated INT DEFAULT 0;
    DECLARE v_last_run DATETIME;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        CALL sp_etl_fail_job(v_job_id, v_error_msg);
        RESIGNAL;
    END;
    
    CALL sp_etl_start_job('load_dim_customer_incremental', v_job_id);
    
    -- Get last run timestamp
    SET v_last_run = fn_get_checkpoint('customers');
    
    -- Find changed records
    CREATE TEMPORARY TABLE tmp_changed_customers AS
    SELECT c.*
    FROM customers c
    WHERE c.updated_at > v_last_run
       OR c.customer_id NOT IN (SELECT customer_id FROM dim_customer WHERE is_current = TRUE);
    
    SELECT COUNT(*) INTO v_rows_processed FROM tmp_changed_customers;
    
    -- Expire changed records
    UPDATE dim_customer dc
    JOIN tmp_changed_customers tc ON dc.customer_id = tc.customer_id
    SET dc.expiry_date = CURRENT_DATE - INTERVAL 1 DAY,
        dc.is_current = FALSE
    WHERE dc.is_current = TRUE;
    
    SET v_rows_updated = ROW_COUNT();
    
    -- Insert new versions
    INSERT INTO dim_customer (
        customer_id, name, email, phone, city, state, zip_code,
        tier_name, segment, effective_date, expiry_date, is_current
    )
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.phone,
        c.city,
        c.state,
        c.zip_code,
        COALESCE(ct.tier_name, 'Unknown'),
        CASE 
            WHEN c.total_spent >= 100000 THEN 'VIP'
            WHEN c.total_spent >= 50000 THEN 'Premium'
            WHEN c.total_spent >= 10000 THEN 'Regular'
            ELSE 'New'
        END,
        CURRENT_DATE,
        '9999-12-31',
        TRUE
    FROM tmp_changed_customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id;
    
    SET v_rows_inserted = ROW_COUNT();
    
    -- Update checkpoint
    CALL sp_update_checkpoint('customers', NULL, NOW());
    
    -- Cleanup
    DROP TEMPORARY TABLE IF EXISTS tmp_changed_customers;
    
    -- Complete job
    CALL sp_etl_complete_job(v_job_id, v_rows_processed, v_rows_inserted, v_rows_updated, 0);
    
    SELECT 'dim_customer incremental load complete' AS result,
           v_rows_processed AS rows_processed,
           v_rows_inserted AS rows_inserted,
           v_rows_updated AS rows_updated;
END //

-- Load dim_product
CREATE PROCEDURE sp_etl_load_dim_product()
BEGIN
    DECLARE v_job_id BIGINT;
    DECLARE v_rows_inserted INT DEFAULT 0;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        CALL sp_etl_fail_job(v_job_id, v_error_msg);
        RESIGNAL;
    END;
    
    CALL sp_etl_start_job('load_dim_product', v_job_id);
    
    -- Expire records for changed products
    UPDATE dim_product dp
    JOIN products p ON dp.product_id = p.product_id AND dp.is_current = TRUE
    SET dp.expiry_date = CURRENT_DATE - INTERVAL 1 DAY,
        dp.is_current = FALSE
    WHERE dp.name != p.name OR dp.price != p.price OR dp.category_id != p.category_id;
    
    -- Insert new/changed products
    INSERT INTO dim_product (
        product_id, sku, name, category_id, category_name,
        price, cost_price, price_range, effective_date
    )
    SELECT 
        p.product_id,
        p.sku,
        p.name,
        p.category_id,
        COALESCE(c.category_name, 'Unknown'),
        p.price,
        p.cost_price,
        CASE 
            WHEN p.price < 10000 THEN 'Budget'
            WHEN p.price < 50000 THEN 'Mid-Range'
            WHEN p.price < 100000 THEN 'Premium'
            ELSE 'Luxury'
        END,
        CURRENT_DATE
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_product dp 
        WHERE dp.product_id = p.product_id AND dp.is_current = TRUE
    );
    
    SET v_rows_inserted = ROW_COUNT();
    
    CALL sp_etl_complete_job(v_job_id, v_rows_inserted, v_rows_inserted, 0, 0);
    
    SELECT 'dim_product loaded' AS result, v_rows_inserted AS rows_inserted;
END //

DELIMITER ;

-- ================================================================
-- SECTION 4: FACT TABLE LOADING
-- ================================================================

DELIMITER //

-- Load fact_sales (incremental)
CREATE PROCEDURE sp_etl_load_fact_sales()
BEGIN
    DECLARE v_job_id BIGINT;
    DECLARE v_rows_inserted INT DEFAULT 0;
    DECLARE v_last_sale_id BIGINT;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        CALL sp_etl_fail_job(v_job_id, v_error_msg);
        RESIGNAL;
    END;
    
    CALL sp_etl_start_job('load_fact_sales', v_job_id);
    
    -- Get last loaded sale_id
    SELECT COALESCE(MAX(sale_id), 0) INTO v_last_sale_id FROM fact_sales;
    
    -- Insert new sales
    INSERT INTO fact_sales (
        date_key, time_key, customer_key, product_key, employee_key,
        payment_key, geo_key, sale_id, quantity, unit_price, discount_amount,
        tax_amount, line_total, cost_amount, profit_amount
    )
    SELECT 
        YEAR(s.sale_date) * 10000 + MONTH(s.sale_date) * 100 + DAY(s.sale_date),
        HOUR(s.sale_date) * 100 + MINUTE(s.sale_date),
        dc.customer_key,
        dp.product_key,
        de.employee_key,
        s.payment_method_id,
        dg.geo_key,
        s.sale_id,
        sd.quantity,
        sd.unit_price,
        COALESCE(sd.discount, 0) * sd.unit_price * sd.quantity / 100,
        (sd.line_total * 0.18),
        sd.line_total,
        COALESCE(p.cost_price, 0) * sd.quantity,
        sd.line_total - COALESCE(p.cost_price, 0) * sd.quantity
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    JOIN dim_customer dc ON s.customer_id = dc.customer_id AND dc.is_current = TRUE
    JOIN dim_product dp ON sd.product_id = dp.product_id AND dp.is_current = TRUE
    LEFT JOIN dim_employee de ON s.employee_id = de.employee_id
    LEFT JOIN customers c ON s.customer_id = c.customer_id
    LEFT JOIN dim_geography dg ON c.city = dg.city AND c.state = dg.state
    JOIN products p ON sd.product_id = p.product_id
    WHERE s.status = 'completed'
      AND s.sale_id > v_last_sale_id;
    
    SET v_rows_inserted = ROW_COUNT();
    
    CALL sp_etl_complete_job(v_job_id, v_rows_inserted, v_rows_inserted, 0, 0);
    
    SELECT 'fact_sales loaded' AS result, v_rows_inserted AS rows_inserted;
END //

-- Refresh daily summary fact
CREATE PROCEDURE sp_etl_refresh_daily_summary(IN p_date DATE)
BEGIN
    DECLARE v_job_id BIGINT;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        CALL sp_etl_fail_job(v_job_id, v_error_msg);
        RESIGNAL;
    END;
    
    CALL sp_etl_start_job('refresh_daily_summary', v_job_id);
    
    -- Delete existing summary for the date
    DELETE FROM fact_daily_sales_summary
    WHERE date_key = YEAR(p_date) * 10000 + MONTH(p_date) * 100 + DAY(p_date);
    
    -- Insert fresh summary
    INSERT INTO fact_daily_sales_summary (
        date_key, geo_key, total_transactions, total_customers,
        total_products_sold, gross_sales, total_discount, net_sales,
        total_cost, gross_profit, avg_transaction_value
    )
    SELECT 
        fs.date_key,
        fs.geo_key,
        COUNT(DISTINCT fs.sale_id),
        COUNT(DISTINCT fs.customer_key),
        SUM(fs.quantity),
        SUM(fs.line_total + fs.discount_amount),
        SUM(fs.discount_amount),
        SUM(fs.line_total),
        SUM(fs.cost_amount),
        SUM(fs.profit_amount),
        AVG(fs.line_total)
    FROM fact_sales fs
    WHERE fs.date_key = YEAR(p_date) * 10000 + MONTH(p_date) * 100 + DAY(p_date)
    GROUP BY fs.date_key, fs.geo_key;
    
    CALL sp_etl_complete_job(v_job_id, ROW_COUNT(), ROW_COUNT(), 0, 1);
    
    SELECT 'Daily summary refreshed' AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 5: MASTER ETL ORCHESTRATION
-- ================================================================

DELIMITER //

-- Run full ETL pipeline
CREATE PROCEDURE sp_etl_run_full_pipeline()
BEGIN
    DECLARE v_start_time DATETIME;
    
    SET v_start_time = NOW();
    
    SELECT 'Starting full ETL pipeline...' AS status;
    
    -- Load dimensions
    CALL sp_etl_load_dim_customer_full();
    CALL sp_etl_load_dim_product();
    
    -- Load facts
    CALL sp_etl_load_fact_sales();
    
    -- Refresh summaries
    CALL sp_etl_refresh_daily_summary(CURRENT_DATE);
    
    SELECT 
        'ETL Pipeline Complete' AS status,
        TIMESTAMPDIFF(SECOND, v_start_time, NOW()) AS duration_seconds;
END //

-- Run incremental ETL
CREATE PROCEDURE sp_etl_run_incremental()
BEGIN
    DECLARE v_start_time DATETIME;
    
    SET v_start_time = NOW();
    
    SELECT 'Starting incremental ETL...' AS status;
    
    -- Incremental dimension loads
    CALL sp_etl_load_dim_customer_incremental();
    CALL sp_etl_load_dim_product();
    
    -- Load new facts
    CALL sp_etl_load_fact_sales();
    
    SELECT 
        'Incremental ETL Complete' AS status,
        TIMESTAMPDIFF(SECOND, v_start_time, NOW()) AS duration_seconds;
END //

DELIMITER ;

-- ================================================================
-- SECTION 6: ETL MONITORING
-- ================================================================

-- View recent ETL jobs
CREATE OR REPLACE VIEW vw_etl_job_status AS
SELECT 
    job_id,
    job_name,
    start_time,
    end_time,
    status,
    TIMESTAMPDIFF(SECOND, start_time, COALESCE(end_time, NOW())) AS duration_seconds,
    rows_processed,
    rows_inserted,
    rows_updated,
    error_message
FROM etl_job_log
ORDER BY start_time DESC
LIMIT 50;

-- View ETL checkpoints
CREATE OR REPLACE VIEW vw_etl_checkpoints AS
SELECT 
    source_table,
    last_extracted_id,
    last_extracted_timestamp,
    last_run_time,
    TIMESTAMPDIFF(HOUR, last_run_time, NOW()) AS hours_since_last_run
FROM etl_checkpoint
ORDER BY last_run_time DESC;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

/*
-- Run full ETL pipeline
CALL sp_etl_run_full_pipeline();

-- Run incremental ETL
CALL sp_etl_run_incremental();

-- Refresh specific date summary
CALL sp_etl_refresh_daily_summary('2024-01-15');

-- Check ETL status
SELECT * FROM vw_etl_job_status;
SELECT * FROM vw_etl_checkpoints;
*/

-- ================================================================
-- END OF ETL PROCEDURES
-- ================================================================
