-- ================================================================
-- QUERY OPTIMIZATION AND PERFORMANCE TUNING
-- EXPLAIN, profiling, index optimization, query tuning techniques
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: EXPLAIN AND EXPLAIN ANALYZE
-- ================================================================

-- Basic EXPLAIN
EXPLAIN SELECT * FROM customers WHERE city = 'Mumbai';

-- EXPLAIN with format options
EXPLAIN FORMAT=JSON SELECT * FROM customers WHERE city = 'Mumbai';

EXPLAIN FORMAT=TREE SELECT * FROM customers WHERE city = 'Mumbai';

-- EXPLAIN ANALYZE (actually executes the query)
EXPLAIN ANALYZE 
SELECT c.name, SUM(s.total_amount) AS total_spent
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
WHERE s.status = 'completed'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC
LIMIT 10;

-- Compare indexed vs non-indexed query
EXPLAIN SELECT * FROM customers WHERE customer_id = 1;  -- Uses PRIMARY KEY
EXPLAIN SELECT * FROM customers WHERE name = 'Rajesh Kumar';  -- May be full scan

-- ================================================================
-- SECTION 2: QUERY PROFILING
-- ================================================================

-- Enable profiling
SET profiling = 1;

-- Run some queries
SELECT COUNT(*) FROM sales;
SELECT AVG(total_amount) FROM sales WHERE status = 'completed';
SELECT customer_id, SUM(total_amount) FROM sales GROUP BY customer_id;

-- Show profiles
SHOW PROFILES;

-- Show detailed profile for a query
SHOW PROFILE FOR QUERY 1;

-- Show specific metrics
SHOW PROFILE CPU, BLOCK IO FOR QUERY 1;

-- Disable profiling
SET profiling = 0;

-- ================================================================
-- SECTION 3: INDEX ANALYSIS
-- ================================================================

-- Show all indexes for a table
SHOW INDEX FROM sales;
SHOW INDEX FROM customers;

-- Check index usage statistics
SELECT 
    table_name,
    index_name,
    stat_name,
    stat_value,
    sample_size
FROM mysql.innodb_index_stats
WHERE database_name = 'retail_sales_advanced'
ORDER BY table_name, index_name;

-- Find unused indexes
SELECT 
    s.table_schema,
    s.table_name,
    s.index_name,
    s.column_name,
    s.seq_in_index
FROM information_schema.statistics s
LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage p
    ON s.table_schema = p.object_schema
    AND s.table_name = p.object_name
    AND s.index_name = p.index_name
WHERE s.table_schema = 'retail_sales_advanced'
  AND (p.count_star IS NULL OR p.count_star = 0)
  AND s.index_name != 'PRIMARY';

-- Find duplicate indexes
SELECT 
    a.table_schema,
    a.table_name,
    a.index_name AS duplicate_index,
    b.index_name AS original_index
FROM 
    information_schema.statistics a
JOIN 
    information_schema.statistics b
ON 
    a.table_schema = b.table_schema
    AND a.table_name = b.table_name
    AND a.column_name = b.column_name
    AND a.seq_in_index = b.seq_in_index
    AND a.index_name != b.index_name
WHERE 
    a.table_schema = 'retail_sales_advanced';

-- ================================================================
-- SECTION 4: QUERY OPTIMIZATION TECHNIQUES
-- ================================================================

-- Technique 1: Use covering indexes
-- Bad: Has to read from table
SELECT name, email FROM customers WHERE city = 'Mumbai';

-- Good: If we have index on (city, name, email), can read from index only
-- CREATE INDEX idx_covering ON customers(city, name, email);
-- SELECT name, email FROM customers WHERE city = 'Mumbai';

-- Technique 2: Avoid SELECT *
-- Bad
SELECT * FROM sales WHERE customer_id = 1;
-- Good
SELECT sale_id, sale_date, total_amount FROM sales WHERE customer_id = 1;

-- Technique 3: Use LIMIT with ORDER BY
-- Bad
SELECT * FROM sales ORDER BY sale_date DESC;
-- Good
SELECT * FROM sales ORDER BY sale_date DESC LIMIT 10;

-- Technique 4: Avoid functions on indexed columns in WHERE
-- Bad (can't use index on sale_date)
SELECT * FROM sales WHERE YEAR(sale_date) = 2024;
-- Good (can use index)
SELECT * FROM sales WHERE sale_date >= '2024-01-01' AND sale_date < '2025-01-01';

-- Technique 5: Use EXISTS instead of IN for large subqueries
-- Potentially slower with large subquery results
SELECT * FROM customers c
WHERE c.customer_id IN (SELECT customer_id FROM sales WHERE total_amount > 100000);

-- Often faster
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM sales s WHERE s.customer_id = c.customer_id AND s.total_amount > 100000);

-- Technique 6: Optimize JOINs
-- Ensure smaller table is on the left (MySQL optimizer usually handles this)
SELECT c.name, s.total_amount
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id;

-- ================================================================
-- SECTION 5: INDEX HINTS
-- ================================================================

-- Force using specific index
SELECT *
FROM sales USE INDEX (idx_customer)
WHERE customer_id = 1;

-- Force ignoring an index
SELECT *
FROM sales IGNORE INDEX (idx_customer)
WHERE customer_id = 1;

-- Force table scan
SELECT *
FROM sales FORCE INDEX (PRIMARY)
WHERE customer_id = 1 AND status = 'completed';

-- ================================================================
-- SECTION 6: OPTIMIZER HINTS (MySQL 8.0+)
-- ================================================================

-- Join order hint
SELECT /*+ JOIN_ORDER(c, s) */ 
    c.name, SUM(s.total_amount)
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.name;

-- No merge hint (prevent view merging)
SELECT /*+ NO_MERGE(v) */ *
FROM (SELECT customer_id, SUM(total_amount) AS total FROM sales GROUP BY customer_id) v
WHERE v.total > 50000;

-- Semijoin/antijoin hints
SELECT /*+ SEMIJOIN(@subq1 MATERIALIZATION) */
    c.name
FROM customers c
WHERE c.customer_id IN (SELECT /*+ QB_NAME(subq1) */ customer_id FROM sales);

-- ================================================================
-- SECTION 7: BATCH PROCESSING FOR LARGE UPDATES
-- ================================================================

-- Bad: Update all rows at once (locks table)
-- UPDATE products SET stock = stock + 10 WHERE category_id = 1;

-- Good: Batch updates
DELIMITER //
CREATE PROCEDURE sp_batch_update_stock(
    IN p_category_id INT,
    IN p_increment INT,
    IN p_batch_size INT
)
BEGIN
    DECLARE v_affected_rows INT DEFAULT 1;
    DECLARE v_total_updated INT DEFAULT 0;
    
    WHILE v_affected_rows > 0 DO
        UPDATE products
        SET stock = stock + p_increment,
            updated_at = NOW()
        WHERE category_id = p_category_id
          AND product_id IN (
              SELECT product_id FROM (
                  SELECT product_id FROM products 
                  WHERE category_id = p_category_id
                  LIMIT p_batch_size
              ) AS batch
          );
        
        SET v_affected_rows = ROW_COUNT();
        SET v_total_updated = v_total_updated + v_affected_rows;
        
        -- Small delay to prevent overloading
        DO SLEEP(0.1);
    END WHILE;
    
    SELECT v_total_updated AS total_rows_updated;
END //
DELIMITER ;

-- ================================================================
-- SECTION 8: QUERY CACHE ANALYSIS (Pre-MySQL 8.0)
-- ================================================================

-- Note: Query cache removed in MySQL 8.0, this is for reference
-- Show query cache status
-- SHOW STATUS LIKE 'Qcache%';

-- For MySQL 8.0+, use application-level caching or ProxySQL

-- ================================================================
-- SECTION 9: TABLE STATISTICS
-- ================================================================

-- Analyze table statistics
ANALYZE TABLE customers, products, sales, sales_details;

-- Show table status
SHOW TABLE STATUS WHERE Name IN ('customers', 'products', 'sales');

-- InnoDB table stats
SELECT 
    table_name,
    n_rows,
    clustered_index_size,
    sum_of_other_index_sizes
FROM mysql.innodb_table_stats
WHERE database_name = 'retail_sales_advanced';

-- ================================================================
-- SECTION 10: SLOW QUERY DETECTION
-- ================================================================

-- Find long-running queries
SELECT 
    id,
    user,
    host,
    db,
    command,
    time,
    state,
    LEFT(info, 100) AS query_preview
FROM information_schema.processlist
WHERE command != 'Sleep'
  AND time > 5
ORDER BY time DESC;

-- Slow query log queries (if enabled)
-- SELECT * FROM mysql.slow_log ORDER BY start_time DESC LIMIT 10;

-- ================================================================
-- SECTION 11: EXECUTION PLAN COMPARISON
-- ================================================================

-- Create procedure to compare execution plans
DELIMITER //
CREATE PROCEDURE sp_compare_query_plans(
    IN p_query1 TEXT,
    IN p_query2 TEXT
)
BEGIN
    -- Note: This is a conceptual example
    -- In practice, you would run EXPLAIN on each query and compare
    
    SELECT 'Query 1 Plan:' AS info;
    SET @sql1 = CONCAT('EXPLAIN FORMAT=JSON ', p_query1);
    PREPARE stmt1 FROM @sql1;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;
    
    SELECT 'Query 2 Plan:' AS info;
    SET @sql2 = CONCAT('EXPLAIN FORMAT=JSON ', p_query2);
    PREPARE stmt2 FROM @sql2;
    EXECUTE stmt2;
    DEALLOCATE PREPARE stmt2;
END //
DELIMITER ;

-- ================================================================
-- SECTION 12: OPTIMIZATION CHECKLIST PROCEDURE
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_optimization_checklist()
BEGIN
    -- Check for tables without primary key
    SELECT 'Tables without Primary Key' AS check_item,
           table_name
    FROM information_schema.tables t
    WHERE table_schema = 'retail_sales_advanced'
      AND table_type = 'BASE TABLE'
      AND NOT EXISTS (
          SELECT 1 FROM information_schema.statistics s
          WHERE s.table_schema = t.table_schema
            AND s.table_name = t.table_name
            AND s.index_name = 'PRIMARY'
      );
    
    -- Check for large tables without indexes
    SELECT 'Large Tables Analysis' AS check_item,
           t.table_name,
           t.table_rows,
           (SELECT COUNT(*) FROM information_schema.statistics s 
            WHERE s.table_schema = t.table_schema AND s.table_name = t.table_name) AS index_count
    FROM information_schema.tables t
    WHERE t.table_schema = 'retail_sales_advanced'
      AND t.table_type = 'BASE TABLE'
      AND t.table_rows > 1000
    ORDER BY t.table_rows DESC;
    
    -- Check for missing foreign key indexes
    SELECT 'Foreign Keys Without Index' AS check_item,
           kcu.table_name,
           kcu.column_name,
           kcu.constraint_name
    FROM information_schema.key_column_usage kcu
    WHERE kcu.table_schema = 'retail_sales_advanced'
      AND kcu.referenced_table_name IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM information_schema.statistics s
          WHERE s.table_schema = kcu.table_schema
            AND s.table_name = kcu.table_name
            AND s.column_name = kcu.column_name
      );
END //
DELIMITER ;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

/*
-- Run optimization checklist
CALL sp_optimization_checklist();

-- Compare two queries
CALL sp_compare_query_plans(
    'SELECT * FROM sales WHERE customer_id = 1',
    'SELECT sale_id, total_amount FROM sales WHERE customer_id = 1'
);

-- Batch update
CALL sp_batch_update_stock(1, 5, 100);
*/

-- ================================================================
-- END OF QUERY OPTIMIZATION
-- ================================================================
