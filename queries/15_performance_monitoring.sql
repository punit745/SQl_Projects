-- ================================================================
-- PERFORMANCE MONITORING QUERIES
-- Database health, slow queries, and optimization insights
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: CURRENT SESSION MONITORING
-- ================================================================

-- Show current processes
SHOW FULL PROCESSLIST;

-- Active queries (non-sleeping connections)
SELECT 
    id,
    user,
    host,
    db,
    command,
    time AS duration_seconds,
    state,
    LEFT(info, 100) AS query_preview
FROM information_schema.processlist
WHERE command != 'Sleep'
ORDER BY time DESC;

-- Long-running queries (> 30 seconds)
SELECT 
    id,
    user,
    db,
    time AS duration_seconds,
    state,
    info AS query
FROM information_schema.processlist
WHERE command != 'Sleep'
  AND time > 30
ORDER BY time DESC;

-- ================================================================
-- SECTION 2: InnoDB ENGINE STATUS
-- ================================================================

-- InnoDB status summary
SHOW ENGINE INNODB STATUS;

-- InnoDB buffer pool stats
SELECT 
    pool_id,
    pool_size,
    free_buffers,
    database_pages,
    old_database_pages,
    modified_database_pages,
    pending_decompress,
    pending_reads,
    pending_flush_lru,
    pending_flush_list
FROM information_schema.innodb_buffer_pool_stats;

-- Buffer pool hit ratio
SELECT 
    (1 - (
        (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads') /
        (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests')
    )) * 100 AS buffer_pool_hit_ratio_pct;

-- ================================================================
-- SECTION 3: TABLE AND INDEX STATISTICS
-- ================================================================

-- Table size information
SELECT 
    table_name,
    table_rows AS estimated_rows,
    ROUND(data_length / 1024 / 1024, 2) AS data_size_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_size_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_size_mb,
    ROUND(data_free / 1024 / 1024, 2) AS free_space_mb
FROM information_schema.tables
WHERE table_schema = 'retail_sales_advanced'
  AND table_type = 'BASE TABLE'
ORDER BY (data_length + index_length) DESC;

-- Index usage statistics
SELECT 
    object_schema,
    object_name,
    index_name,
    count_read,
    count_write,
    count_fetch,
    count_insert,
    count_update,
    count_delete
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = 'retail_sales_advanced'
ORDER BY count_read + count_write DESC;

-- Unused indexes
SELECT 
    s.table_name,
    s.index_name,
    s.column_name
FROM information_schema.statistics s
LEFT JOIN performance_schema.table_io_waits_summary_by_index_usage p
    ON s.table_schema = p.object_schema
    AND s.table_name = p.object_name
    AND s.index_name = p.index_name
WHERE s.table_schema = 'retail_sales_advanced'
  AND s.index_name != 'PRIMARY'
  AND (p.count_star IS NULL OR p.count_star = 0)
ORDER BY s.table_name, s.index_name;

-- ================================================================
-- SECTION 4: QUERY PERFORMANCE ANALYSIS
-- ================================================================

-- Most expensive queries (by total execution time)
SELECT 
    DIGEST_TEXT,
    COUNT_STAR AS exec_count,
    ROUND(SUM_TIMER_WAIT / 1000000000000, 3) AS total_time_sec,
    ROUND(AVG_TIMER_WAIT / 1000000000, 3) AS avg_time_ms,
    ROUND(MAX_TIMER_WAIT / 1000000000, 3) AS max_time_ms,
    SUM_ROWS_EXAMINED AS rows_examined,
    SUM_ROWS_SENT AS rows_sent
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'retail_sales_advanced'
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 10;

-- Queries with high row examination (potential optimization candidates)
SELECT 
    DIGEST_TEXT,
    COUNT_STAR AS exec_count,
    SUM_ROWS_EXAMINED AS total_rows_examined,
    SUM_ROWS_SENT AS total_rows_sent,
    ROUND(SUM_ROWS_EXAMINED / NULLIF(SUM_ROWS_SENT, 0), 0) AS rows_examined_per_row_sent
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'retail_sales_advanced'
  AND SUM_ROWS_EXAMINED > 1000
ORDER BY SUM_ROWS_EXAMINED / NULLIF(SUM_ROWS_SENT, 0) DESC
LIMIT 10;

-- Full table scans
SELECT 
    DIGEST_TEXT,
    COUNT_STAR AS exec_count,
    SUM_NO_INDEX_USED AS no_index_count,
    SUM_NO_GOOD_INDEX_USED AS bad_index_count
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'retail_sales_advanced'
  AND (SUM_NO_INDEX_USED > 0 OR SUM_NO_GOOD_INDEX_USED > 0)
ORDER BY SUM_NO_INDEX_USED DESC
LIMIT 10;

-- ================================================================
-- SECTION 5: LOCK AND WAIT ANALYSIS
-- ================================================================

-- Current locks
SELECT 
    r.trx_id AS waiting_trx_id,
    r.trx_mysql_thread_id AS waiting_thread,
    r.trx_query AS waiting_query,
    b.trx_id AS blocking_trx_id,
    b.trx_mysql_thread_id AS blocking_thread,
    b.trx_query AS blocking_query
FROM information_schema.innodb_lock_waits w
JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;

-- Lock wait statistics
SELECT 
    object_schema,
    object_name,
    index_name,
    count_star AS lock_waits,
    sum_timer_wait / 1000000000 AS total_wait_ms
FROM performance_schema.table_lock_waits_summary_by_table
WHERE object_schema = 'retail_sales_advanced'
ORDER BY sum_timer_wait DESC;

-- ================================================================
-- SECTION 6: CONNECTION AND THREAD STATISTICS
-- ================================================================

-- Connection statistics
SELECT 
    variable_name,
    variable_value
FROM performance_schema.global_status
WHERE variable_name IN (
    'Connections',
    'Max_used_connections',
    'Threads_connected',
    'Threads_running',
    'Aborted_clients',
    'Aborted_connects'
);

-- Connection settings
SELECT 
    variable_name,
    variable_value
FROM performance_schema.global_variables
WHERE variable_name IN (
    'max_connections',
    'wait_timeout',
    'interactive_timeout',
    'thread_cache_size'
);

-- ================================================================
-- SECTION 7: DISK I/O ANALYSIS
-- ================================================================

-- File I/O statistics
SELECT 
    file_name,
    count_read,
    count_write,
    ROUND(sum_number_of_bytes_read / 1024 / 1024, 2) AS read_mb,
    ROUND(sum_number_of_bytes_write / 1024 / 1024, 2) AS write_mb
FROM performance_schema.file_summary_by_instance
WHERE file_name LIKE '%retail_sales%'
ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;

-- Table I/O wait summary
SELECT 
    object_schema,
    object_name,
    count_star AS io_operations,
    count_read,
    count_write,
    ROUND(sum_timer_wait / 1000000000, 3) AS total_wait_ms
FROM performance_schema.table_io_waits_summary_by_table
WHERE object_schema = 'retail_sales_advanced'
ORDER BY sum_timer_wait DESC;

-- ================================================================
-- SECTION 8: MEMORY USAGE
-- ================================================================

-- Memory usage by event
SELECT 
    event_name,
    current_count_used,
    ROUND(current_number_of_bytes_used / 1024 / 1024, 2) AS current_mb,
    ROUND(high_number_of_bytes_used / 1024 / 1024, 2) AS high_water_mark_mb
FROM performance_schema.memory_summary_global_by_event_name
WHERE current_number_of_bytes_used > 0
ORDER BY current_number_of_bytes_used DESC
LIMIT 10;

-- ================================================================
-- SECTION 9: CREATE MONITORING VIEWS
-- ================================================================

-- Dashboard view for overall health
CREATE OR REPLACE VIEW vw_database_health AS
SELECT 
    'Buffer Pool Hit Ratio' AS metric,
    CONCAT(
        ROUND((1 - (
            (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads') /
            NULLIF((SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests'), 0)
        )) * 100, 2), '%'
    ) AS value,
    CASE 
        WHEN (1 - (
            (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads') /
            NULLIF((SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests'), 0)
        )) > 0.95 THEN 'GOOD'
        WHEN (1 - (
            (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads') /
            NULLIF((SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests'), 0)
        )) > 0.90 THEN 'WARN'
        ELSE 'CRITICAL'
    END AS status
UNION ALL
SELECT 
    'Active Connections',
    (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Threads_connected'),
    CASE 
        WHEN (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Threads_connected') < 
             (SELECT variable_value FROM performance_schema.global_variables WHERE variable_name = 'max_connections') * 0.7 
        THEN 'GOOD'
        ELSE 'WARN'
    END
UNION ALL
SELECT 
    'Database Size (MB)',
    (SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) 
     FROM information_schema.tables WHERE table_schema = 'retail_sales_advanced'),
    'INFO'
UNION ALL
SELECT 
    'Total Tables',
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_schema = 'retail_sales_advanced' AND table_type = 'BASE TABLE'),
    'INFO';

-- Slow query candidates view
CREATE OR REPLACE VIEW vw_slow_query_candidates AS
SELECT 
    LEFT(DIGEST_TEXT, 200) AS query_preview,
    COUNT_STAR AS exec_count,
    ROUND(AVG_TIMER_WAIT / 1000000000, 3) AS avg_ms,
    ROUND(MAX_TIMER_WAIT / 1000000000, 3) AS max_ms,
    SUM_ROWS_EXAMINED AS rows_examined,
    SUM_NO_INDEX_USED AS no_index_used,
    CASE 
        WHEN AVG_TIMER_WAIT / 1000000000 > 1000 THEN 'SLOW'
        WHEN AVG_TIMER_WAIT / 1000000000 > 100 THEN 'NEEDS_REVIEW'
        ELSE 'OK'
    END AS status
FROM performance_schema.events_statements_summary_by_digest
WHERE SCHEMA_NAME = 'retail_sales_advanced'
  AND COUNT_STAR > 10
ORDER BY AVG_TIMER_WAIT DESC;

-- ================================================================
-- SECTION 10: MONITORING STORED PROCEDURES
-- ================================================================

DELIMITER //

-- Get comprehensive performance report
CREATE PROCEDURE sp_performance_report()
BEGIN
    SELECT 'DATABASE HEALTH' AS section;
    SELECT * FROM vw_database_health;
    
    SELECT 'TABLE SIZES' AS section;
    SELECT 
        table_name,
        table_rows,
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
    FROM information_schema.tables
    WHERE table_schema = 'retail_sales_advanced'
      AND table_type = 'BASE TABLE'
    ORDER BY data_length + index_length DESC
    LIMIT 10;
    
    SELECT 'SLOW QUERY CANDIDATES' AS section;
    SELECT * FROM vw_slow_query_candidates LIMIT 5;
    
    SELECT 'ACTIVE QUERIES' AS section;
    SELECT id, user, db, time, state, LEFT(info, 100) AS query
    FROM information_schema.processlist
    WHERE command != 'Sleep'
    ORDER BY time DESC
    LIMIT 5;
END //

-- Kill long-running queries
CREATE PROCEDURE sp_kill_long_queries(
    IN p_max_duration_seconds INT
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id BIGINT;
    DECLARE cursor_processes CURSOR FOR
        SELECT id FROM information_schema.processlist
        WHERE command != 'Sleep'
          AND time > p_max_duration_seconds
          AND user != 'system user';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cursor_processes;
    
    read_loop: LOOP
        FETCH cursor_processes INTO v_id;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Log before killing
        SELECT CONCAT('Killing process: ', v_id) AS action;
        
        -- Kill the process
        SET @kill_sql = CONCAT('KILL ', v_id);
        PREPARE stmt FROM @kill_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    
    CLOSE cursor_processes;
END //

DELIMITER ;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

/*
-- Get performance report
CALL sp_performance_report();

-- Check database health
SELECT * FROM vw_database_health;

-- Find slow queries
SELECT * FROM vw_slow_query_candidates;

-- Kill queries running more than 5 minutes
CALL sp_kill_long_queries(300);
*/

-- ================================================================
-- END OF PERFORMANCE MONITORING
-- ================================================================
