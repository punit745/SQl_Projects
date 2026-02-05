-- ================================================================
-- TABLE PARTITIONING IN MYSQL
-- Range, List, Hash, and Key partitioning strategies
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: RANGE PARTITIONING
-- ================================================================

-- Range partition by date (most common for time-series data)
CREATE TABLE sales_partitioned (
    sale_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    employee_id INT,
    sale_date DATETIME NOT NULL,
    payment_method_id INT,
    subtotal DECIMAL(12, 2),
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2),
    total_amount DECIMAL(12, 2),
    status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'completed',
    PRIMARY KEY (sale_id, sale_date)
)
PARTITION BY RANGE (YEAR(sale_date)) (
    PARTITION p2022 VALUES LESS THAN (2023),
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Range partition by value
CREATE TABLE customers_partitioned (
    customer_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    total_spent DECIMAL(12, 2) DEFAULT 0,
    tier_id INT DEFAULT 1,
    PRIMARY KEY (customer_id, total_spent)
)
PARTITION BY RANGE (total_spent) (
    PARTITION p_bronze VALUES LESS THAN (10000),
    PARTITION p_silver VALUES LESS THAN (50000),
    PARTITION p_gold VALUES LESS THAN (100000),
    PARTITION p_platinum VALUES LESS THAN MAXVALUE
);

-- Range columns (multiple columns)
CREATE TABLE audit_log_partitioned (
    log_id BIGINT NOT NULL AUTO_INCREMENT,
    table_name VARCHAR(50),
    operation_type ENUM('INSERT', 'UPDATE', 'DELETE'),
    created_at DATETIME NOT NULL,
    PRIMARY KEY (log_id, created_at)
)
PARTITION BY RANGE COLUMNS(created_at) (
    PARTITION p_2024_q1 VALUES LESS THAN ('2024-04-01'),
    PARTITION p_2024_q2 VALUES LESS THAN ('2024-07-01'),
    PARTITION p_2024_q3 VALUES LESS THAN ('2024-10-01'),
    PARTITION p_2024_q4 VALUES LESS THAN ('2025-01-01'),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- ================================================================
-- SECTION 2: LIST PARTITIONING
-- ================================================================

-- List partition by category
CREATE TABLE products_by_category (
    product_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    price DECIMAL(10, 2),
    stock INT DEFAULT 0,
    PRIMARY KEY (product_id, category_id)
)
PARTITION BY LIST (category_id) (
    PARTITION p_electronics VALUES IN (1, 2),
    PARTITION p_mobile VALUES IN (3),
    PARTITION p_appliances VALUES IN (4),
    PARTITION p_audio_video VALUES IN (5),
    PARTITION p_other VALUES IN (6, 7, 8, 9, 10)
);

-- List partition by region
CREATE TABLE customers_by_region (
    customer_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    city VARCHAR(50),
    PRIMARY KEY (customer_id, state)
)
PARTITION BY LIST COLUMNS(state) (
    PARTITION p_north VALUES IN ('Delhi', 'Punjab', 'Haryana', 'Uttar Pradesh'),
    PARTITION p_south VALUES IN ('Karnataka', 'Tamil Nadu', 'Kerala', 'Telangana'),
    PARTITION p_west VALUES IN ('Maharashtra', 'Gujarat', 'Rajasthan', 'Goa'),
    PARTITION p_east VALUES IN ('West Bengal', 'Odisha', 'Bihar', 'Jharkhand')
);

-- ================================================================
-- SECTION 3: HASH PARTITIONING
-- ================================================================

-- Hash partition (even distribution)
CREATE TABLE sales_hash_partitioned (
    sale_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATETIME NOT NULL,
    total_amount DECIMAL(12, 2),
    PRIMARY KEY (sale_id, customer_id)
)
PARTITION BY HASH(customer_id)
PARTITIONS 8;

-- Linear hash (faster partition adding/dropping)
CREATE TABLE logs_linear_hash (
    log_id BIGINT NOT NULL AUTO_INCREMENT,
    log_type VARCHAR(50),
    message TEXT,
    created_at DATETIME,
    PRIMARY KEY (log_id)
)
PARTITION BY LINEAR HASH(log_id)
PARTITIONS 4;

-- ================================================================
-- SECTION 4: KEY PARTITIONING
-- ================================================================

-- Key partition (uses MySQL's internal hashing)
CREATE TABLE sessions_key_partitioned (
    session_id VARCHAR(64) NOT NULL,
    user_id INT,
    data JSON,
    created_at DATETIME,
    expires_at DATETIME,
    PRIMARY KEY (session_id)
)
PARTITION BY KEY(session_id)
PARTITIONS 16;

-- Key partition on multiple columns
CREATE TABLE user_activity (
    activity_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    activity_date DATE NOT NULL,
    PRIMARY KEY (activity_id, user_id, activity_date)
)
PARTITION BY KEY(user_id, activity_date)
PARTITIONS 8;

-- ================================================================
-- SECTION 5: SUBPARTITIONING (COMPOSITE PARTITIONING)
-- ================================================================

-- Range-Hash subpartitioning
CREATE TABLE sales_subpartitioned (
    sale_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    sale_date DATETIME NOT NULL,
    total_amount DECIMAL(12, 2),
    PRIMARY KEY (sale_id, sale_date, customer_id)
)
PARTITION BY RANGE (YEAR(sale_date))
SUBPARTITION BY HASH(customer_id)
SUBPARTITIONS 4 (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- ================================================================
-- SECTION 6: PARTITION MANAGEMENT
-- ================================================================

-- Add new partition
ALTER TABLE sales_partitioned 
ADD PARTITION (PARTITION p2026 VALUES LESS THAN (2027));

-- Drop old partition (removes data!)
-- ALTER TABLE sales_partitioned DROP PARTITION p2022;

-- Truncate partition (faster than DELETE)
-- ALTER TABLE sales_partitioned TRUNCATE PARTITION p2022;

-- Reorganize partitions
-- ALTER TABLE sales_partitioned 
-- REORGANIZE PARTITION p_future INTO (
--     PARTITION p2026 VALUES LESS THAN (2027),
--     PARTITION p_future VALUES LESS THAN MAXVALUE
-- );

-- Coalesce hash partitions (reduce number)
-- ALTER TABLE sales_hash_partitioned COALESCE PARTITION 2;

-- Add hash partitions
-- ALTER TABLE sales_hash_partitioned ADD PARTITION PARTITIONS 4;

-- Rebuild partition
-- ALTER TABLE sales_partitioned REBUILD PARTITION p2024;

-- Analyze partition
ALTER TABLE sales_partitioned ANALYZE PARTITION p2024;

-- Optimize partition
-- ALTER TABLE sales_partitioned OPTIMIZE PARTITION p2024;

-- Check partition
ALTER TABLE sales_partitioned CHECK PARTITION p2024;

-- Repair partition
-- ALTER TABLE sales_partitioned REPAIR PARTITION p2024;

-- ================================================================
-- SECTION 7: QUERYING PARTITIONED TABLES
-- ================================================================

-- Query specific partition
SELECT * FROM sales_partitioned PARTITION (p2024)
WHERE total_amount > 50000;

-- Query multiple partitions
SELECT * FROM sales_partitioned PARTITION (p2023, p2024)
WHERE status = 'completed';

-- Check partition pruning with EXPLAIN
EXPLAIN SELECT * FROM sales_partitioned 
WHERE sale_date >= '2024-01-01' AND sale_date < '2025-01-01';

-- Partition pruning works with range queries
EXPLAIN SELECT COUNT(*) FROM sales_partitioned 
WHERE YEAR(sale_date) = 2024;

-- ================================================================
-- SECTION 8: PARTITION INFORMATION
-- ================================================================

-- Show partition info
SELECT 
    PARTITION_NAME,
    TABLE_ROWS,
    AVG_ROW_LENGTH,
    DATA_LENGTH,
    INDEX_LENGTH
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
  AND TABLE_NAME = 'sales_partitioned'
ORDER BY PARTITION_ORDINAL_POSITION;

-- Check which partition a row would go to
SELECT PARTITION(sale_date, 1, 2024) AS partition_id
FROM (SELECT '2024-06-15' AS sale_date) t;

-- ================================================================
-- SECTION 9: PARTITION MAINTENANCE PROCEDURES
-- ================================================================

DELIMITER //

-- Procedure to add monthly partitions
CREATE PROCEDURE sp_add_monthly_partitions(
    IN p_table_name VARCHAR(64),
    IN p_months_ahead INT
)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_partition_name VARCHAR(64);
    DECLARE v_partition_date DATE;
    DECLARE v_sql TEXT;
    
    WHILE i < p_months_ahead DO
        SET v_partition_date = DATE_ADD(CURRENT_DATE, INTERVAL i MONTH);
        SET v_partition_name = CONCAT('p', DATE_FORMAT(v_partition_date, '%Y%m'));
        
        -- Build ALTER TABLE statement
        SET v_sql = CONCAT(
            'ALTER TABLE ', p_table_name, 
            ' ADD PARTITION (PARTITION ', v_partition_name,
            ' VALUES LESS THAN (''', 
            DATE_FORMAT(DATE_ADD(v_partition_date, INTERVAL 1 MONTH), '%Y-%m-01'),
            '''))'
        );
        
        -- Execute (wrap in handler for already exists)
        BEGIN
            DECLARE CONTINUE HANDLER FOR 1517 BEGIN END; -- Duplicate partition
            SET @sql = v_sql;
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
        END;
        
        SET i = i + 1;
    END WHILE;
    
    SELECT CONCAT('Added ', p_months_ahead, ' monthly partitions') AS result;
END //

-- Procedure to archive old partitions
CREATE PROCEDURE sp_archive_old_partitions(
    IN p_source_table VARCHAR(64),
    IN p_archive_table VARCHAR(64),
    IN p_partition_name VARCHAR(64)
)
BEGIN
    DECLARE v_sql TEXT;
    
    -- Copy data to archive
    SET v_sql = CONCAT(
        'INSERT INTO ', p_archive_table,
        ' SELECT * FROM ', p_source_table,
        ' PARTITION (', p_partition_name, ')'
    );
    SET @sql = v_sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Drop the partition
    SET v_sql = CONCAT(
        'ALTER TABLE ', p_source_table,
        ' DROP PARTITION ', p_partition_name
    );
    SET @sql = v_sql;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SELECT CONCAT('Archived and dropped partition: ', p_partition_name) AS result;
END //

DELIMITER ;

-- ================================================================
-- SECTION 10: PARTITION BEST PRACTICES
-- ================================================================

/*
PARTITION BEST PRACTICES:

1. Choose partition key wisely:
   - Most queries should be able to prune partitions
   - Common columns: date, region, category
   
2. Don't over-partition:
   - Too many partitions increase overhead
   - Aim for partitions with millions of rows, not thousands
   
3. Include partition key in primary key:
   - Required for unique indexes to work properly
   
4. Use partition pruning:
   - Always include partition key in WHERE clause
   - Use EXPLAIN to verify pruning is happening
   
5. Regular maintenance:
   - Add new partitions before they're needed
   - Archive/drop old partitions to keep table manageable
   
6. Avoid:
   - Partitioning small tables
   - Too many partitions (limit ~1024 recommended)
   - Partitioning on frequently updated columns
*/

-- ================================================================
-- SECTION 11: CLEANUP (Optional - Uncomment to run)
-- ================================================================

/*
DROP TABLE IF EXISTS sales_partitioned;
DROP TABLE IF EXISTS customers_partitioned;
DROP TABLE IF EXISTS audit_log_partitioned;
DROP TABLE IF EXISTS products_by_category;
DROP TABLE IF EXISTS customers_by_region;
DROP TABLE IF EXISTS sales_hash_partitioned;
DROP TABLE IF EXISTS logs_linear_hash;
DROP TABLE IF EXISTS sessions_key_partitioned;
DROP TABLE IF EXISTS user_activity;
DROP TABLE IF EXISTS sales_subpartitioned;
*/

-- ================================================================
-- END OF PARTITIONING
-- ================================================================
