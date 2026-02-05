-- ================================================================
-- API-READY STORED PROCEDURES
-- REST-style procedures returning JSON for API integration
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: CUSTOMER API PROCEDURES
-- ================================================================

DELIMITER //

-- Get customer by ID (returns JSON)
CREATE PROCEDURE api_get_customer(
    IN p_customer_id INT
)
BEGIN
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'customer_id', c.customer_id,
            'name', c.name,
            'email', c.email,
            'phone', c.phone,
            'address', JSON_OBJECT(
                'street', c.address,
                'city', c.city,
                'state', c.state,
                'zip_code', c.zip_code
            ),
            'tier', JSON_OBJECT(
                'id', ct.tier_id,
                'name', ct.tier_name,
                'discount_pct', ct.discount_percentage
            ),
            'stats', JSON_OBJECT(
                'total_spent', c.total_spent,
                'registration_date', c.registration_date,
                'last_purchase_date', c.last_purchase_date
            )
        )
    ) AS response
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    WHERE c.customer_id = p_customer_id;
    
    IF ROW_COUNT() = 0 THEN
        SELECT JSON_OBJECT(
            'success', FALSE,
            'error', JSON_OBJECT(
                'code', 'NOT_FOUND',
                'message', CONCAT('Customer with ID ', p_customer_id, ' not found')
            )
        ) AS response;
    END IF;
END //

-- List customers with pagination
CREATE PROCEDURE api_list_customers(
    IN p_page INT,
    IN p_page_size INT,
    IN p_sort_by VARCHAR(50),
    IN p_sort_order VARCHAR(4)
)
BEGIN
    DECLARE v_offset INT;
    DECLARE v_total INT;
    
    SET p_page = COALESCE(p_page, 1);
    SET p_page_size = COALESCE(p_page_size, 10);
    SET p_sort_by = COALESCE(p_sort_by, 'customer_id');
    SET p_sort_order = COALESCE(p_sort_order, 'ASC');
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total count
    SELECT COUNT(*) INTO v_total FROM customers;
    
    -- Build dynamic query
    SET @sql = CONCAT(
        'SELECT JSON_OBJECT(',
        '''success'', TRUE,',
        '''data'', JSON_OBJECT(',
        '''customers'', (',
        'SELECT JSON_ARRAYAGG(',
        'JSON_OBJECT(',
        '''customer_id'', c.customer_id,',
        '''name'', c.name,',
        '''email'', c.email,',
        '''city'', c.city,',
        '''tier_name'', ct.tier_name,',
        '''total_spent'', c.total_spent',
        '))',
        'FROM customers c ',
        'LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id ',
        'ORDER BY ', p_sort_by, ' ', p_sort_order, ' ',
        'LIMIT ', p_page_size, ' OFFSET ', v_offset,
        '),',
        '''pagination'', JSON_OBJECT(',
        '''page'', ', p_page, ',',
        '''page_size'', ', p_page_size, ',',
        '''total_records'', ', v_total, ',',
        '''total_pages'', CEILING(', v_total, ' / ', p_page_size, ')',
        ')',
        ')',
        ') AS response'
    );
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

-- Search customers
CREATE PROCEDURE api_search_customers(
    IN p_search_term VARCHAR(100)
)
BEGIN
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'results', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'customer_id', c.customer_id,
                        'name', c.name,
                        'email', c.email,
                        'city', c.city,
                        'match_type', CASE 
                            WHEN c.name LIKE CONCAT('%', p_search_term, '%') THEN 'name'
                            WHEN c.email LIKE CONCAT('%', p_search_term, '%') THEN 'email'
                            ELSE 'other'
                        END
                    )
                )
                FROM customers c
                WHERE c.name LIKE CONCAT('%', p_search_term, '%')
                   OR c.email LIKE CONCAT('%', p_search_term, '%')
                   OR c.phone LIKE CONCAT('%', p_search_term, '%')
                LIMIT 20
            ),
            'search_term', p_search_term
        )
    ) AS response;
END //

-- Create customer
CREATE PROCEDURE api_create_customer(
    IN p_name VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_phone VARCHAR(20),
    IN p_city VARCHAR(50),
    IN p_state VARCHAR(50),
    OUT p_response JSON
)
BEGIN
    DECLARE v_customer_id INT;
    DECLARE v_error_msg TEXT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SET p_response = JSON_OBJECT(
            'success', FALSE,
            'error', JSON_OBJECT(
                'code', 'CREATE_FAILED',
                'message', v_error_msg
            )
        );
    END;
    
    -- Validate email uniqueness
    IF EXISTS (SELECT 1 FROM customers WHERE email = p_email) THEN
        SET p_response = JSON_OBJECT(
            'success', FALSE,
            'error', JSON_OBJECT(
                'code', 'DUPLICATE_EMAIL',
                'message', 'Email already exists'
            )
        );
    ELSE
        INSERT INTO customers (name, email, phone, city, state, tier_id)
        VALUES (p_name, p_email, p_phone, p_city, p_state, 1);
        
        SET v_customer_id = LAST_INSERT_ID();
        
        SET p_response = JSON_OBJECT(
            'success', TRUE,
            'data', JSON_OBJECT(
                'customer_id', v_customer_id,
                'message', 'Customer created successfully'
            )
        );
    END IF;
    
    SELECT p_response AS response;
END //

-- Update customer
CREATE PROCEDURE api_update_customer(
    IN p_customer_id INT,
    IN p_updates JSON
)
BEGIN
    DECLARE v_name VARCHAR(100);
    DECLARE v_phone VARCHAR(20);
    DECLARE v_city VARCHAR(50);
    DECLARE v_state VARCHAR(50);
    
    -- Extract values from JSON (NULL if not provided)
    SET v_name = JSON_UNQUOTE(JSON_EXTRACT(p_updates, '$.name'));
    SET v_phone = JSON_UNQUOTE(JSON_EXTRACT(p_updates, '$.phone'));
    SET v_city = JSON_UNQUOTE(JSON_EXTRACT(p_updates, '$.city'));
    SET v_state = JSON_UNQUOTE(JSON_EXTRACT(p_updates, '$.state'));
    
    UPDATE customers
    SET 
        name = COALESCE(NULLIF(v_name, 'null'), name),
        phone = COALESCE(NULLIF(v_phone, 'null'), phone),
        city = COALESCE(NULLIF(v_city, 'null'), city),
        state = COALESCE(NULLIF(v_state, 'null'), state)
    WHERE customer_id = p_customer_id;
    
    IF ROW_COUNT() > 0 THEN
        CALL api_get_customer(p_customer_id);
    ELSE
        SELECT JSON_OBJECT(
            'success', FALSE,
            'error', JSON_OBJECT(
                'code', 'NOT_FOUND',
                'message', 'Customer not found'
            )
        ) AS response;
    END IF;
END //

-- ================================================================
-- SECTION 2: PRODUCT API PROCEDURES
-- ================================================================

-- Get product by ID
CREATE PROCEDURE api_get_product(
    IN p_product_id INT
)
BEGIN
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'product_id', p.product_id,
            'sku', p.sku,
            'name', p.name,
            'category', JSON_OBJECT(
                'id', c.category_id,
                'name', c.category_name
            ),
            'pricing', JSON_OBJECT(
                'price', p.price,
                'cost_price', p.cost_price,
                'profit_margin', ROUND((p.price - COALESCE(p.cost_price, 0)) / p.price * 100, 2)
            ),
            'inventory', JSON_OBJECT(
                'stock', p.stock,
                'reorder_level', p.reorder_level,
                'status', CASE 
                    WHEN p.stock = 0 THEN 'out_of_stock'
                    WHEN p.stock <= p.reorder_level THEN 'low_stock'
                    ELSE 'in_stock'
                END
            )
        )
    ) AS response
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.category_id
    WHERE p.product_id = p_product_id;
END //

-- List products with filters
CREATE PROCEDURE api_list_products(
    IN p_category_id INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2),
    IN p_in_stock_only BOOLEAN,
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT;
    
    SET p_page = COALESCE(p_page, 1);
    SET p_page_size = COALESCE(p_page_size, 20);
    SET v_offset = (p_page - 1) * p_page_size;
    
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'products', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'product_id', p.product_id,
                        'sku', p.sku,
                        'name', p.name,
                        'category_name', c.category_name,
                        'price', p.price,
                        'stock', p.stock,
                        'status', CASE 
                            WHEN p.stock = 0 THEN 'out_of_stock'
                            WHEN p.stock <= p.reorder_level THEN 'low_stock'
                            ELSE 'in_stock'
                        END
                    )
                )
                FROM products p
                LEFT JOIN categories c ON p.category_id = c.category_id
                WHERE (p_category_id IS NULL OR p.category_id = p_category_id)
                  AND (p_min_price IS NULL OR p.price >= p_min_price)
                  AND (p_max_price IS NULL OR p.price <= p_max_price)
                  AND (p_in_stock_only IS NULL OR p_in_stock_only = FALSE OR p.stock > 0)
                ORDER BY p.name
                LIMIT p_page_size OFFSET v_offset
            ),
            'filters', JSON_OBJECT(
                'category_id', p_category_id,
                'min_price', p_min_price,
                'max_price', p_max_price,
                'in_stock_only', p_in_stock_only
            )
        )
    ) AS response;
END //

-- ================================================================
-- SECTION 3: SALES API PROCEDURES
-- ================================================================

-- Get sale details
CREATE PROCEDURE api_get_sale(
    IN p_sale_id INT
)
BEGIN
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'sale_id', s.sale_id,
            'sale_date', s.sale_date,
            'status', s.status,
            'customer', JSON_OBJECT(
                'id', c.customer_id,
                'name', c.name,
                'email', c.email
            ),
            'employee', JSON_OBJECT(
                'id', e.employee_id,
                'name', e.name
            ),
            'payment', JSON_OBJECT(
                'method', pm.method_name,
                'subtotal', s.subtotal,
                'discount', s.discount_amount,
                'tax', s.tax_amount,
                'total', s.total_amount
            ),
            'items', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'product_id', sd.product_id,
                        'product_name', p.name,
                        'quantity', sd.quantity,
                        'unit_price', sd.unit_price,
                        'discount_pct', sd.discount,
                        'line_total', sd.line_total
                    )
                )
                FROM sales_details sd
                JOIN products p ON sd.product_id = p.product_id
                WHERE sd.sale_id = s.sale_id
            )
        )
    ) AS response
    FROM sales s
    LEFT JOIN customers c ON s.customer_id = c.customer_id
    LEFT JOIN employees e ON s.employee_id = e.employee_id
    LEFT JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id
    WHERE s.sale_id = p_sale_id;
END //

-- Create sale
CREATE PROCEDURE api_create_sale(
    IN p_customer_id INT,
    IN p_employee_id INT,
    IN p_payment_method_id INT,
    IN p_items JSON
)
BEGIN
    DECLARE v_sale_id INT;
    DECLARE v_subtotal DECIMAL(12,2) DEFAULT 0;
    DECLARE v_discount DECIMAL(10,2) DEFAULT 0;
    DECLARE v_tax DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_i INT DEFAULT 0;
    DECLARE v_item_count INT;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_unit_price DECIMAL(10,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT JSON_OBJECT(
            'success', FALSE,
            'error', JSON_OBJECT(
                'code', 'CREATE_FAILED',
                'message', 'Failed to create sale'
            )
        ) AS response;
    END;
    
    START TRANSACTION;
    
    -- Get item count
    SET v_item_count = JSON_LENGTH(p_items);
    
    -- Create sale header
    INSERT INTO sales (customer_id, employee_id, payment_method_id, subtotal, discount_amount, tax_amount, total_amount, status)
    VALUES (p_customer_id, p_employee_id, p_payment_method_id, 0, 0, 0, 0, 'pending');
    
    SET v_sale_id = LAST_INSERT_ID();
    
    -- Add items
    WHILE v_i < v_item_count DO
        SET v_product_id = JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id'));
        SET v_quantity = JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity'));
        
        SELECT price INTO v_unit_price FROM products WHERE product_id = v_product_id;
        
        INSERT INTO sales_details (sale_id, product_id, quantity, unit_price, discount, line_total)
        VALUES (v_sale_id, v_product_id, v_quantity, v_unit_price, 0, v_unit_price * v_quantity);
        
        SET v_subtotal = v_subtotal + (v_unit_price * v_quantity);
        SET v_i = v_i + 1;
    END WHILE;
    
    -- Calculate totals
    SET v_tax = v_subtotal * 0.18;
    SET v_total = v_subtotal + v_tax - v_discount;
    
    -- Update sale header
    UPDATE sales
    SET subtotal = v_subtotal,
        tax_amount = v_tax,
        total_amount = v_total,
        status = 'completed'
    WHERE sale_id = v_sale_id;
    
    COMMIT;
    
    -- Return created sale
    CALL api_get_sale(v_sale_id);
END //

-- ================================================================
-- SECTION 4: ANALYTICS API PROCEDURES
-- ================================================================

-- Dashboard summary
CREATE PROCEDURE api_get_dashboard_summary(
    IN p_date_from DATE,
    IN p_date_to DATE
)
BEGIN
    SET p_date_from = COALESCE(p_date_from, DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY));
    SET p_date_to = COALESCE(p_date_to, CURRENT_DATE);
    
    SELECT JSON_OBJECT(
        'success', TRUE,
        'data', JSON_OBJECT(
            'period', JSON_OBJECT(
                'from', p_date_from,
                'to', p_date_to
            ),
            'sales', JSON_OBJECT(
                'total_revenue', (SELECT COALESCE(SUM(total_amount), 0) FROM sales WHERE status = 'completed' AND DATE(sale_date) BETWEEN p_date_from AND p_date_to),
                'total_orders', (SELECT COUNT(*) FROM sales WHERE status = 'completed' AND DATE(sale_date) BETWEEN p_date_from AND p_date_to),
                'avg_order_value', (SELECT COALESCE(AVG(total_amount), 0) FROM sales WHERE status = 'completed' AND DATE(sale_date) BETWEEN p_date_from AND p_date_to)
            ),
            'customers', JSON_OBJECT(
                'total_customers', (SELECT COUNT(*) FROM customers),
                'new_customers', (SELECT COUNT(*) FROM customers WHERE registration_date BETWEEN p_date_from AND p_date_to),
                'active_customers', (SELECT COUNT(DISTINCT customer_id) FROM sales WHERE DATE(sale_date) BETWEEN p_date_from AND p_date_to)
            ),
            'products', JSON_OBJECT(
                'total_products', (SELECT COUNT(*) FROM products),
                'low_stock_count', (SELECT COUNT(*) FROM products WHERE stock <= reorder_level AND stock > 0),
                'out_of_stock_count', (SELECT COUNT(*) FROM products WHERE stock = 0)
            ),
            'top_products', (
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'product_id', p.product_id,
                        'name', p.name,
                        'revenue', revenue
                    )
                )
                FROM (
                    SELECT sd.product_id, SUM(sd.line_total) AS revenue
                    FROM sales_details sd
                    JOIN sales s ON sd.sale_id = s.sale_id
                    WHERE s.status = 'completed' AND DATE(s.sale_date) BETWEEN p_date_from AND p_date_to
                    GROUP BY sd.product_id
                    ORDER BY revenue DESC
                    LIMIT 5
                ) t
                JOIN products p ON t.product_id = p.product_id
            )
        )
    ) AS response;
END //

-- Sales trend
CREATE PROCEDURE api_get_sales_trend(
    IN p_period VARCHAR(10),  -- 'daily', 'weekly', 'monthly'
    IN p_limit INT
)
BEGIN
    SET p_limit = COALESCE(p_limit, 12);
    
    CASE p_period
        WHEN 'daily' THEN
            SELECT JSON_OBJECT(
                'success', TRUE,
                'data', JSON_OBJECT(
                    'period_type', 'daily',
                    'trend', (
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                                'date', sale_date,
                                'revenue', revenue,
                                'orders', order_count
                            )
                        )
                        FROM (
                            SELECT 
                                DATE(sale_date) AS sale_date,
                                SUM(total_amount) AS revenue,
                                COUNT(*) AS order_count
                            FROM sales
                            WHERE status = 'completed'
                            GROUP BY DATE(sale_date)
                            ORDER BY sale_date DESC
                            LIMIT p_limit
                        ) t
                    )
                )
            ) AS response;
            
        WHEN 'weekly' THEN
            SELECT JSON_OBJECT(
                'success', TRUE,
                'data', JSON_OBJECT(
                    'period_type', 'weekly',
                    'trend', (
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                                'year', year,
                                'week', week,
                                'revenue', revenue,
                                'orders', order_count
                            )
                        )
                        FROM (
                            SELECT 
                                YEAR(sale_date) AS year,
                                WEEK(sale_date) AS week,
                                SUM(total_amount) AS revenue,
                                COUNT(*) AS order_count
                            FROM sales
                            WHERE status = 'completed'
                            GROUP BY YEAR(sale_date), WEEK(sale_date)
                            ORDER BY year DESC, week DESC
                            LIMIT p_limit
                        ) t
                    )
                )
            ) AS response;
            
        ELSE -- monthly
            SELECT JSON_OBJECT(
                'success', TRUE,
                'data', JSON_OBJECT(
                    'period_type', 'monthly',
                    'trend', (
                        SELECT JSON_ARRAYAGG(
                            JSON_OBJECT(
                                'year', year,
                                'month', month,
                                'revenue', revenue,
                                'orders', order_count
                            )
                        )
                        FROM (
                            SELECT 
                                YEAR(sale_date) AS year,
                                MONTH(sale_date) AS month,
                                SUM(total_amount) AS revenue,
                                COUNT(*) AS order_count
                            FROM sales
                            WHERE status = 'completed'
                            GROUP BY YEAR(sale_date), MONTH(sale_date)
                            ORDER BY year DESC, month DESC
                            LIMIT p_limit
                        ) t
                    )
                )
            ) AS response;
    END CASE;
END //

DELIMITER ;

-- ================================================================
-- USAGE EXAMPLES
-- ================================================================

/*
-- Customer APIs
CALL api_get_customer(1);
CALL api_list_customers(1, 10, 'name', 'ASC');
CALL api_search_customers('raj');

-- Product APIs
CALL api_get_product(1);
CALL api_list_products(NULL, 10000, 100000, TRUE, 1, 20);

-- Sales APIs
CALL api_get_sale(1);
CALL api_create_sale(1, 2, 1, '[{"product_id": 1, "quantity": 2}, {"product_id": 5, "quantity": 1}]');

-- Analytics APIs
CALL api_get_dashboard_summary('2024-01-01', '2024-12-31');
CALL api_get_sales_trend('monthly', 12);
*/

-- ================================================================
-- END OF API PROCEDURES
-- ================================================================
