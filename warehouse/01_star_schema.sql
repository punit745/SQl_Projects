-- ================================================================
-- STAR SCHEMA FOR DATA WAREHOUSING
-- Dimension and Fact tables for analytics
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: DIMENSION TABLES
-- ================================================================

-- Date Dimension
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_of_week TINYINT,
    day_name VARCHAR(10),
    day_of_month TINYINT,
    day_of_year SMALLINT,
    week_of_year TINYINT,
    month_number TINYINT,
    month_name VARCHAR(10),
    quarter TINYINT,
    year SMALLINT,
    is_weekend BOOLEAN,
    is_holiday BOOLEAN DEFAULT FALSE,
    fiscal_year SMALLINT,
    fiscal_quarter TINYINT,
    INDEX idx_full_date (full_date),
    INDEX idx_year_month (year, month_number)
);

-- Time Dimension
CREATE TABLE dim_time (
    time_key INT PRIMARY KEY,
    full_time TIME NOT NULL,
    hour TINYINT,
    minute TINYINT,
    second TINYINT,
    am_pm CHAR(2),
    hour_12 TINYINT,
    time_period VARCHAR(20),  -- Morning, Afternoon, Evening, Night
    is_business_hours BOOLEAN,
    INDEX idx_hour (hour)
);

-- Customer Dimension (Slowly Changing Dimension Type 2)
CREATE TABLE dim_customer (
    customer_key INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,  -- Natural key from source
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    tier_name VARCHAR(50),
    segment VARCHAR(50),
    effective_date DATE NOT NULL,
    expiry_date DATE DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE,
    INDEX idx_customer_id (customer_id),
    INDEX idx_current (is_current),
    INDEX idx_city_state (city, state)
);

-- Product Dimension
CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,  -- Natural key
    sku VARCHAR(50),
    name VARCHAR(100),
    category_id INT,
    category_name VARCHAR(100),
    price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    price_range VARCHAR(20),  -- Budget, Mid-Range, Premium, Luxury
    effective_date DATE NOT NULL,
    expiry_date DATE DEFAULT '9999-12-31',
    is_current BOOLEAN DEFAULT TRUE,
    INDEX idx_product_id (product_id),
    INDEX idx_category (category_id),
    INDEX idx_current (is_current)
);

-- Employee Dimension
CREATE TABLE dim_employee (
    employee_key INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    name VARCHAR(100),
    email VARCHAR(100),
    position VARCHAR(50),
    department VARCHAR(50),
    hire_date DATE,
    manager_id INT,
    manager_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_employee_id (employee_id),
    INDEX idx_department (department)
);

-- Payment Method Dimension
CREATE TABLE dim_payment_method (
    payment_key INT PRIMARY KEY,
    method_name VARCHAR(50),
    category VARCHAR(50),  -- Cash, Card, Digital
    processing_fee_pct DECIMAL(5, 2),
    is_active BOOLEAN
);

-- Geography Dimension
CREATE TABLE dim_geography (
    geo_key INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    region VARCHAR(50),  -- North, South, East, West
    country VARCHAR(50) DEFAULT 'India',
    UNIQUE KEY uk_city_state (city, state)
);

-- ================================================================
-- SECTION 2: FACT TABLES
-- ================================================================

-- Sales Fact Table (Transaction grain)
CREATE TABLE fact_sales (
    sale_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Dimension Keys
    date_key INT NOT NULL,
    time_key INT,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    employee_key INT,
    payment_key INT,
    geo_key INT,
    
    -- Degenerate Dimensions
    sale_id INT,  -- Original transaction ID
    
    -- Measures
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    line_total DECIMAL(12, 2) NOT NULL,
    cost_amount DECIMAL(10, 2),
    profit_amount DECIMAL(10, 2),
    
    -- Foreign Keys
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    
    -- Indexes for common queries
    INDEX idx_date (date_key),
    INDEX idx_customer (customer_key),
    INDEX idx_product (product_key),
    INDEX idx_date_product (date_key, product_key),
    INDEX idx_date_customer (date_key, customer_key)
);

-- Daily Sales Summary Fact (Aggregated grain)
CREATE TABLE fact_daily_sales_summary (
    summary_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    date_key INT NOT NULL,
    geo_key INT,
    
    -- Measures
    total_transactions INT,
    total_customers INT,
    total_products_sold INT,
    gross_sales DECIMAL(15, 2),
    total_discount DECIMAL(12, 2),
    net_sales DECIMAL(15, 2),
    total_cost DECIMAL(15, 2),
    gross_profit DECIMAL(15, 2),
    avg_transaction_value DECIMAL(10, 2),
    
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    UNIQUE KEY uk_date_geo (date_key, geo_key),
    INDEX idx_date (date_key)
);

-- Inventory Snapshot Fact (Periodic snapshot)
CREATE TABLE fact_inventory_snapshot (
    snapshot_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    
    -- Measures
    quantity_on_hand INT,
    quantity_on_order INT,
    reorder_level INT,
    days_of_supply INT,
    inventory_value DECIMAL(15, 2),
    
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    UNIQUE KEY uk_date_product (date_key, product_key)
);

-- Customer Activity Fact (Accumulating snapshot)
CREATE TABLE fact_customer_lifetime (
    customer_key INT PRIMARY KEY,
    
    -- Milestone dates
    first_purchase_date_key INT,
    last_purchase_date_key INT,
    first_return_date_key INT,
    
    -- Lifetime measures
    total_orders INT DEFAULT 0,
    total_items INT DEFAULT 0,
    total_revenue DECIMAL(15, 2) DEFAULT 0,
    total_returns INT DEFAULT 0,
    total_return_value DECIMAL(12, 2) DEFAULT 0,
    net_revenue DECIMAL(15, 2) DEFAULT 0,
    avg_order_value DECIMAL(10, 2),
    days_since_first_purchase INT,
    days_since_last_purchase INT,
    purchase_frequency_days DECIMAL(10, 2),
    
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
);

-- ================================================================
-- SECTION 3: POPULATE DIMENSION TABLES
-- ================================================================

-- Populate Date Dimension (5 years of dates)
DELIMITER //
CREATE PROCEDURE sp_populate_dim_date(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    DECLARE current_date_val DATE;
    
    SET current_date_val = start_date;
    
    WHILE current_date_val <= end_date DO
        INSERT IGNORE INTO dim_date (
            date_key, full_date, day_of_week, day_name,
            day_of_month, day_of_year, week_of_year,
            month_number, month_name, quarter, year,
            is_weekend, fiscal_year, fiscal_quarter
        )
        VALUES (
            YEAR(current_date_val) * 10000 + MONTH(current_date_val) * 100 + DAY(current_date_val),
            current_date_val,
            DAYOFWEEK(current_date_val),
            DAYNAME(current_date_val),
            DAY(current_date_val),
            DAYOFYEAR(current_date_val),
            WEEK(current_date_val),
            MONTH(current_date_val),
            MONTHNAME(current_date_val),
            QUARTER(current_date_val),
            YEAR(current_date_val),
            DAYOFWEEK(current_date_val) IN (1, 7),
            CASE WHEN MONTH(current_date_val) >= 4 THEN YEAR(current_date_val) 
                 ELSE YEAR(current_date_val) - 1 END,
            CASE 
                WHEN MONTH(current_date_val) IN (4,5,6) THEN 1
                WHEN MONTH(current_date_val) IN (7,8,9) THEN 2
                WHEN MONTH(current_date_val) IN (10,11,12) THEN 3
                ELSE 4
            END
        );
        
        SET current_date_val = DATE_ADD(current_date_val, INTERVAL 1 DAY);
    END WHILE;
END //
DELIMITER ;

-- Populate Time Dimension
DELIMITER //
CREATE PROCEDURE sp_populate_dim_time()
BEGIN
    DECLARE h INT DEFAULT 0;
    DECLARE m INT DEFAULT 0;
    
    WHILE h < 24 DO
        SET m = 0;
        WHILE m < 60 DO
            INSERT INTO dim_time (
                time_key, full_time, hour, minute, second,
                am_pm, hour_12, time_period, is_business_hours
            )
            VALUES (
                h * 100 + m,
                MAKETIME(h, m, 0),
                h,
                m,
                0,
                IF(h < 12, 'AM', 'PM'),
                IF(h = 0, 12, IF(h > 12, h - 12, h)),
                CASE 
                    WHEN h >= 5 AND h < 12 THEN 'Morning'
                    WHEN h >= 12 AND h < 17 THEN 'Afternoon'
                    WHEN h >= 17 AND h < 21 THEN 'Evening'
                    ELSE 'Night'
                END,
                h >= 9 AND h < 18
            );
            SET m = m + 1;
        END WHILE;
        SET h = h + 1;
    END WHILE;
END //
DELIMITER ;

-- ================================================================
-- SECTION 4: ETL PROCEDURES
-- ================================================================

-- Load Customer Dimension (SCD Type 2)
DELIMITER //
CREATE PROCEDURE sp_load_dim_customer()
BEGIN
    -- Expire changed records
    UPDATE dim_customer dc
    JOIN customers c ON dc.customer_id = c.customer_id AND dc.is_current = TRUE
    SET dc.expiry_date = CURRENT_DATE - INTERVAL 1 DAY,
        dc.is_current = FALSE
    WHERE dc.name != c.name
       OR dc.email != c.email
       OR dc.city != c.city
       OR dc.tier_id != c.tier_id;
    
    -- Insert new and changed records
    INSERT INTO dim_customer (
        customer_id, name, email, phone, city, state, zip_code,
        tier_name, segment, effective_date
    )
    SELECT 
        c.customer_id,
        c.name,
        c.email,
        c.phone,
        c.city,
        c.state,
        c.zip_code,
        ct.tier_name,
        CASE 
            WHEN c.total_spent >= 100000 THEN 'VIP'
            WHEN c.total_spent >= 50000 THEN 'Premium'
            WHEN c.total_spent >= 10000 THEN 'Regular'
            ELSE 'New'
        END,
        CURRENT_DATE
    FROM customers c
    LEFT JOIN customer_tiers ct ON c.tier_id = ct.tier_id
    WHERE NOT EXISTS (
        SELECT 1 FROM dim_customer dc 
        WHERE dc.customer_id = c.customer_id AND dc.is_current = TRUE
    );
END //
DELIMITER ;

-- Load Product Dimension (SCD Type 2)
DELIMITER //
CREATE PROCEDURE sp_load_dim_product()
BEGIN
    -- Expire changed records
    UPDATE dim_product dp
    JOIN products p ON dp.product_id = p.product_id AND dp.is_current = TRUE
    SET dp.expiry_date = CURRENT_DATE - INTERVAL 1 DAY,
        dp.is_current = FALSE
    WHERE dp.name != p.name OR dp.price != p.price OR dp.category_id != p.category_id;
    
    -- Insert new and changed records
    INSERT INTO dim_product (
        product_id, sku, name, category_id, category_name,
        price, cost_price, price_range, effective_date
    )
    SELECT 
        p.product_id,
        p.sku,
        p.name,
        p.category_id,
        c.category_name,
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
END //
DELIMITER ;

-- Load Sales Fact
DELIMITER //
CREATE PROCEDURE sp_load_fact_sales()
BEGIN
    INSERT INTO fact_sales (
        date_key, time_key, customer_key, product_key, employee_key,
        payment_key, sale_id, quantity, unit_price, discount_amount,
        tax_amount, line_total, cost_amount, profit_amount
    )
    SELECT 
        YEAR(s.sale_date) * 10000 + MONTH(s.sale_date) * 100 + DAY(s.sale_date),
        HOUR(s.sale_date) * 100 + MINUTE(s.sale_date),
        dc.customer_key,
        dp.product_key,
        de.employee_key,
        s.payment_method_id,
        s.sale_id,
        sd.quantity,
        sd.unit_price,
        sd.discount * sd.unit_price * sd.quantity / 100,
        (sd.line_total * 0.18),
        sd.line_total,
        p.cost_price * sd.quantity,
        sd.line_total - (p.cost_price * sd.quantity)
    FROM sales s
    JOIN sales_details sd ON s.sale_id = sd.sale_id
    JOIN dim_customer dc ON s.customer_id = dc.customer_id AND dc.is_current = TRUE
    JOIN dim_product dp ON sd.product_id = dp.product_id AND dp.is_current = TRUE
    LEFT JOIN dim_employee de ON s.employee_id = de.employee_id
    JOIN products p ON sd.product_id = p.product_id
    WHERE s.status = 'completed'
      AND NOT EXISTS (
          SELECT 1 FROM fact_sales fs WHERE fs.sale_id = s.sale_id
      );
END //
DELIMITER ;

-- ================================================================
-- SECTION 5: INITIALIZE DATA
-- ================================================================

-- Populate date dimension
CALL sp_populate_dim_date('2020-01-01', '2030-12-31');

-- Populate time dimension
CALL sp_populate_dim_time();

-- Load dimensions and facts
-- CALL sp_load_dim_customer();
-- CALL sp_load_dim_product();
-- CALL sp_load_fact_sales();

-- ================================================================
-- END OF STAR SCHEMA
-- ================================================================
