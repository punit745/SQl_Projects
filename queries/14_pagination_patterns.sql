-- ================================================================
-- PAGINATION PATTERNS FOR APIs
-- Offset, cursor-based, and keyset pagination
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: SIMPLE OFFSET PAGINATION
-- ================================================================

-- Basic offset pagination
SELECT * FROM customers
ORDER BY customer_id
LIMIT 10 OFFSET 0;  -- Page 1

SELECT * FROM customers
ORDER BY customer_id
LIMIT 10 OFFSET 10;  -- Page 2

SELECT * FROM customers
ORDER BY customer_id
LIMIT 10 OFFSET 20;  -- Page 3

-- Offset pagination with total count
DELIMITER //
CREATE PROCEDURE sp_paginate_customers_offset(
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    DECLARE v_total INT;
    
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total count
    SELECT COUNT(*) INTO v_total FROM customers;
    
    -- Return paginated results
    SELECT 
        c.*,
        v_total AS total_records,
        CEILING(v_total / p_page_size) AS total_pages,
        p_page AS current_page,
        p_page_size AS page_size
    FROM customers c
    ORDER BY customer_id
    LIMIT p_page_size OFFSET v_offset;
END //
DELIMITER ;

-- ================================================================
-- SECTION 2: CURSOR-BASED PAGINATION (More efficient for large datasets)
-- ================================================================

-- Forward cursor pagination using last seen ID
DELIMITER //
CREATE PROCEDURE sp_paginate_customers_cursor(
    IN p_last_id INT,
    IN p_limit INT,
    IN p_direction VARCHAR(10)  -- 'next' or 'prev'
)
BEGIN
    IF p_direction = 'next' OR p_last_id IS NULL THEN
        -- Get next page
        SELECT 
            c.*,
            (SELECT MIN(customer_id) FROM customers) AS first_id,
            (SELECT MAX(customer_id) FROM customers) AS last_id
        FROM customers c
        WHERE p_last_id IS NULL OR c.customer_id > p_last_id
        ORDER BY c.customer_id ASC
        LIMIT p_limit;
    ELSE
        -- Get previous page
        SELECT * FROM (
            SELECT 
                c.*,
                (SELECT MIN(customer_id) FROM customers) AS first_id,
                (SELECT MAX(customer_id) FROM customers) AS last_id
            FROM customers c
            WHERE c.customer_id < p_last_id
            ORDER BY c.customer_id DESC
            LIMIT p_limit
        ) t
        ORDER BY customer_id ASC;
    END IF;
END //
DELIMITER ;

-- Cursor pagination with encoded cursor
DELIMITER //
CREATE PROCEDURE sp_paginate_with_cursor(
    IN p_cursor VARCHAR(255),  -- Base64 encoded cursor
    IN p_limit INT
)
BEGIN
    DECLARE v_id INT;
    DECLARE v_timestamp DATETIME;
    
    IF p_cursor IS NOT NULL THEN
        -- Decode cursor (format: "id:timestamp" base64 encoded)
        SET @decoded = FROM_BASE64(p_cursor);
        SET v_id = CAST(SUBSTRING_INDEX(@decoded, ':', 1) AS SIGNED);
        SET v_timestamp = SUBSTRING_INDEX(@decoded, ':', -1);
    END IF;
    
    SELECT 
        s.*,
        -- Generate cursor for next page
        TO_BASE64(CONCAT(s.sale_id, ':', s.sale_date)) AS next_cursor
    FROM sales s
    WHERE p_cursor IS NULL 
       OR (s.sale_date, s.sale_id) > (v_timestamp, v_id)
    ORDER BY s.sale_date, s.sale_id
    LIMIT p_limit;
END //
DELIMITER ;

-- ================================================================
-- SECTION 3: KEYSET PAGINATION (Most efficient for sorted data)
-- ================================================================

-- Keyset pagination on single column
DELIMITER //
CREATE PROCEDURE sp_paginate_keyset_simple(
    IN p_last_value DECIMAL(12,2),
    IN p_last_id INT,
    IN p_limit INT
)
BEGIN
    SELECT *
    FROM customers
    WHERE (p_last_value IS NULL AND p_last_id IS NULL)
       OR (total_spent, customer_id) > (p_last_value, p_last_id)
    ORDER BY total_spent, customer_id
    LIMIT p_limit;
END //
DELIMITER ;

-- Keyset pagination with multiple sort columns
DELIMITER //
CREATE PROCEDURE sp_paginate_keyset_multi(
    IN p_last_date DATE,
    IN p_last_amount DECIMAL(12,2),
    IN p_last_id INT,
    IN p_limit INT
)
BEGIN
    SELECT *
    FROM sales
    WHERE (p_last_date IS NULL)
       OR (DATE(sale_date), total_amount, sale_id) > (p_last_date, p_last_amount, p_last_id)
    ORDER BY DATE(sale_date), total_amount, sale_id
    LIMIT p_limit;
END //
DELIMITER ;

-- ================================================================
-- SECTION 4: INFINITE SCROLL / LOAD MORE PAGINATION
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_load_more_sales(
    IN p_last_sale_date DATETIME,
    IN p_batch_size INT
)
BEGIN
    DECLARE v_has_more BOOLEAN;
    DECLARE v_result_count INT;
    
    SET p_batch_size = COALESCE(p_batch_size, 20);
    
    -- Get results
    SELECT 
        s.sale_id,
        s.sale_date,
        c.name AS customer_name,
        s.total_amount,
        s.status
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    WHERE p_last_sale_date IS NULL OR s.sale_date < p_last_sale_date
    ORDER BY s.sale_date DESC
    LIMIT p_batch_size + 1;  -- Fetch one extra to check if more exist
    
    -- Check if more results exist
    SELECT COUNT(*) INTO v_result_count
    FROM sales
    WHERE p_last_sale_date IS NULL OR sale_date < p_last_sale_date
    LIMIT p_batch_size + 1;
    
    SET v_has_more = v_result_count > p_batch_size;
    
    SELECT v_has_more AS has_more_results;
END //
DELIMITER ;

-- ================================================================
-- SECTION 5: SEARCH WITH PAGINATION
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_search_products_paginated(
    IN p_search_term VARCHAR(100),
    IN p_category_id INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2),
    IN p_sort_by VARCHAR(50),
    IN p_sort_order VARCHAR(4),
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    DECLARE v_total INT;
    
    SET p_page = COALESCE(p_page, 1);
    SET p_page_size = LEAST(COALESCE(p_page_size, 20), 100);  -- Max 100
    SET p_sort_by = COALESCE(p_sort_by, 'name');
    SET p_sort_order = COALESCE(p_sort_order, 'ASC');
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total count with filters
    SELECT COUNT(*) INTO v_total
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    WHERE (p_search_term IS NULL OR p.name LIKE CONCAT('%', p_search_term, '%'))
      AND (p_category_id IS NULL OR p.category_id = p_category_id)
      AND (p_min_price IS NULL OR p.price >= p_min_price)
      AND (p_max_price IS NULL OR p.price <= p_max_price);
    
    -- Return results with pagination metadata
    SET @sql = CONCAT(
        'SELECT ',
        '  p.product_id, p.name, p.sku, p.price, p.stock, ',
        '  c.category_name, ',
        '  ', v_total, ' AS total_records, ',
        '  CEILING(', v_total, ' / ', p_page_size, ') AS total_pages, ',
        '  ', p_page, ' AS current_page ',
        'FROM products p ',
        'LEFT JOIN categories c ON p.category_id = c.category_id ',
        'WHERE 1=1 '
    );
    
    IF p_search_term IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.name LIKE ''%', p_search_term, '%''');
    END IF;
    IF p_category_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.category_id = ', p_category_id);
    END IF;
    IF p_min_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.price >= ', p_min_price);
    END IF;
    IF p_max_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.price <= ', p_max_price);
    END IF;
    
    SET @sql = CONCAT(@sql, ' ORDER BY p.', p_sort_by, ' ', p_sort_order);
    SET @sql = CONCAT(@sql, ' LIMIT ', p_page_size, ' OFFSET ', v_offset);
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- ================================================================
-- SECTION 6: PAGINATION WITH AGGREGATES
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_paginate_customer_summary(
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    DECLARE v_total INT;
    
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total
    SELECT COUNT(*) INTO v_total FROM customers;
    
    -- Return paginated summary
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.city,
        ct.tier_name,
        c.total_spent,
        COUNT(s.sale_id) AS order_count,
        MAX(s.sale_date) AS last_order_date,
        v_total AS total_records,
        CEILING(v_total / p_page_size) AS total_pages
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    LEFT JOIN sales s ON c.customer_id = s.customer_id AND s.status = 'completed'
    GROUP BY c.customer_id, c.name, c.email, c.city, ct.tier_name, c.total_spent
    ORDER BY c.total_spent DESC
    LIMIT p_page_size OFFSET v_offset;
END //
DELIMITER ;

-- ================================================================
-- SECTION 7: JSON API PAGINATION RESPONSE
-- ================================================================

DELIMITER //
CREATE PROCEDURE sp_paginate_json_response(
    IN p_table VARCHAR(50),
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    DECLARE v_total INT;
    
    SET p_page = COALESCE(p_page, 1);
    SET p_page_size = COALESCE(p_page_size, 10);
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total count
    SET @count_sql = CONCAT('SELECT COUNT(*) INTO @total FROM ', p_table);
    PREPARE count_stmt FROM @count_sql;
    EXECUTE count_stmt;
    DEALLOCATE PREPARE count_stmt;
    SET v_total = @total;
    
    -- Build JSON response
    IF p_table = 'customers' THEN
        SELECT JSON_OBJECT(
            'data', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'id', customer_id,
                        'name', name,
                        'email', email,
                        'city', city
                    )
                )
                FROM (
                    SELECT customer_id, name, email, city
                    FROM customers
                    ORDER BY customer_id
                    LIMIT p_page_size OFFSET v_offset
                ) t
            ),
            'pagination', JSON_OBJECT(
                'page', p_page,
                'page_size', p_page_size,
                'total_records', v_total,
                'total_pages', CEILING(v_total / p_page_size),
                'has_next', p_page < CEILING(v_total / p_page_size),
                'has_prev', p_page > 1
            ),
            'links', JSON_OBJECT(
                'self', CONCAT('/api/customers?page=', p_page, '&page_size=', p_page_size),
                'first', CONCAT('/api/customers?page=1&page_size=', p_page_size),
                'last', CONCAT('/api/customers?page=', CEILING(v_total / p_page_size), '&page_size=', p_page_size),
                'next', IF(p_page < CEILING(v_total / p_page_size), 
                           CONCAT('/api/customers?page=', p_page + 1, '&page_size=', p_page_size), 
                           NULL),
                'prev', IF(p_page > 1, 
                           CONCAT('/api/customers?page=', p_page - 1, '&page_size=', p_page_size), 
                           NULL)
            )
        ) AS response;
    END IF;
END //
DELIMITER ;

-- ================================================================
-- SECTION 8: COMPARISON OF PAGINATION METHODS
-- ================================================================

/*
PAGINATION METHOD COMPARISON:

1. OFFSET PAGINATION
   Pros: Simple, random page access, familiar to users
   Cons: Slow on large datasets (MySQL must scan all offset rows)
   Best for: Small datasets, admin panels
   
2. CURSOR/KEYSET PAGINATION
   Pros: Fast on large datasets, consistent results
   Cons: No random page access, must traverse sequentially
   Best for: APIs, infinite scroll, large datasets
   
3. SEEK METHOD (Keyset with multiple columns)
   Pros: Very fast, works with any sort order
   Cons: Complex queries, requires unique sort key
   Best for: High-performance APIs, real-time feeds

PERFORMANCE COMPARISON:
- Offset with 1M rows, page 10000: ~500ms
- Cursor with 1M rows, any position: ~5ms

RECOMMENDATION:
- < 10,000 rows: Offset pagination is fine
- > 10,000 rows: Consider cursor/keyset pagination
- Real-time feeds: Always use cursor-based
*/

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

/*
-- Offset pagination
CALL sp_paginate_customers_offset(1, 10);  -- Page 1
CALL sp_paginate_customers_offset(2, 10);  -- Page 2

-- Cursor pagination
CALL sp_paginate_customers_cursor(NULL, 10, 'next');     -- First page
CALL sp_paginate_customers_cursor(10, 10, 'next');       -- After ID 10
CALL sp_paginate_customers_cursor(20, 10, 'prev');       -- Before ID 20

-- Search with pagination
CALL sp_search_products_paginated('Laptop', NULL, NULL, NULL, 'price', 'DESC', 1, 10);

-- JSON API response
CALL sp_paginate_json_response('customers', 1, 10);
*/

-- ================================================================
-- END OF PAGINATION PATTERNS
-- ================================================================
