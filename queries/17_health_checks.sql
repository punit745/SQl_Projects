-- ================================================================
-- HEALTH CHECK QUERIES
-- Database health monitoring and diagnostics
-- ================================================================

USE retail_sales_advanced;

-- Health check results table
CREATE TABLE IF NOT EXISTS health_check_results (
    check_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    check_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    status ENUM('OK', 'WARNING', 'CRITICAL') NOT NULL,
    message TEXT,
    metric_value DECIMAL(20,4),
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

-- Connection health check
CREATE PROCEDURE health_check_connections()
BEGIN
    DECLARE v_max_conn INT;
    DECLARE v_current_conn INT;
    DECLARE v_conn_pct DECIMAL(5,2);
    
    SELECT @@max_connections INTO v_max_conn;
    SELECT COUNT(*) INTO v_current_conn FROM information_schema.processlist;
    SET v_conn_pct = v_current_conn / v_max_conn * 100;
    
    INSERT INTO health_check_results (check_name, category, status, message, metric_value)
    VALUES (
        'Connection Usage', 'Connections',
        CASE WHEN v_conn_pct > 90 THEN 'CRITICAL' WHEN v_conn_pct > 70 THEN 'WARNING' ELSE 'OK' END,
        CONCAT(v_current_conn, ' of ', v_max_conn, ' (', ROUND(v_conn_pct, 1), '%)'),
        v_conn_pct
    );
END //

-- Table health check
CREATE PROCEDURE health_check_tables()
BEGIN
    INSERT INTO health_check_results (check_name, category, status, message, metric_value)
    SELECT 
        CONCAT('Table Size: ', table_name), 'Disk', 'OK',
        CONCAT(ROUND((data_length + index_length)/1024/1024, 2), ' MB'),
        (data_length + index_length)/1024/1024
    FROM information_schema.tables
    WHERE table_schema = 'retail_sales_advanced' AND table_type = 'BASE TABLE'
    ORDER BY data_length + index_length DESC LIMIT 10;
END //

-- Data quality check
CREATE PROCEDURE health_check_data_quality()
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count FROM sales_details sd
    LEFT JOIN sales s ON sd.sale_id = s.sale_id WHERE s.sale_id IS NULL;
    
    INSERT INTO health_check_results (check_name, category, status, message, metric_value)
    VALUES ('Orphan Records', 'Data Quality',
        IF(v_count > 0, 'CRITICAL', 'OK'),
        CONCAT(v_count, ' orphan records'), v_count);
END //

-- Run all health checks
CREATE PROCEDURE run_all_health_checks()
BEGIN
    DELETE FROM health_check_results WHERE checked_at < DATE_SUB(NOW(), INTERVAL 24 HOUR);
    CALL health_check_connections();
    CALL health_check_tables();
    CALL health_check_data_quality();
    
    SELECT check_name, category, status, message FROM health_check_results
    WHERE checked_at >= DATE_SUB(NOW(), INTERVAL 1 MINUTE)
    ORDER BY FIELD(status, 'CRITICAL', 'WARNING', 'OK');
END //

DELIMITER ;

-- Usage: CALL run_all_health_checks();
