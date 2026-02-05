-- ================================================================
-- JSON FUNCTIONS IN MySQL
-- Demonstrating JSON data type and JSON functions
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- SECTION 1: JSON COLUMN OPERATIONS
-- ================================================================

-- Add JSON columns to customers table (if not already added)
-- ALTER TABLE customers ADD COLUMN preferences JSON;
-- ALTER TABLE customers ADD COLUMN metadata JSON;

-- ================================================================
-- SECTION 2: INSERTING JSON DATA
-- ================================================================

-- Insert JSON data using JSON_OBJECT
UPDATE customers 
SET preferences = JSON_OBJECT(
    'newsletter', TRUE,
    'sms_notifications', FALSE,
    'email_notifications', TRUE,
    'preferred_contact_time', 'evening',
    'communication_channels', JSON_ARRAY('email', 'whatsapp'),
    'preferred_categories', JSON_ARRAY(1, 2, 3),
    'language', 'en'
)
WHERE customer_id = 1;

-- Insert JSON data using JSON_ARRAY
UPDATE customers 
SET preferences = JSON_OBJECT(
    'newsletter', FALSE,
    'sms_notifications', TRUE,
    'preferred_categories', JSON_ARRAY(2, 4),
    'interests', JSON_ARRAY('electronics', 'computers', 'gaming'),
    'settings', JSON_OBJECT(
        'dark_mode', TRUE,
        'currency', 'INR',
        'timezone', 'Asia/Kolkata'
    )
)
WHERE customer_id = 2;

-- Insert nested JSON structure
UPDATE customers 
SET preferences = JSON_OBJECT(
    'newsletter', TRUE,
    'address_book', JSON_ARRAY(
        JSON_OBJECT('type', 'home', 'city', 'Mumbai', 'is_default', TRUE),
        JSON_OBJECT('type', 'work', 'city', 'Pune', 'is_default', FALSE)
    ),
    'payment_preferences', JSON_OBJECT(
        'default_method', 'upi',
        'saved_cards', JSON_ARRAY('**** 1234', '**** 5678')
    )
)
WHERE customer_id = 3;

-- ================================================================
-- SECTION 3: EXTRACTING JSON DATA
-- ================================================================

-- Extract specific values using JSON_EXTRACT
SELECT 
    customer_id,
    name,
    JSON_EXTRACT(preferences, '$.newsletter') AS newsletter_opt_in,
    JSON_EXTRACT(preferences, '$.language') AS preferred_language,
    JSON_EXTRACT(preferences, '$.preferred_categories') AS preferred_categories
FROM customers
WHERE preferences IS NOT NULL;

-- Use -> operator (shorthand for JSON_EXTRACT)
SELECT 
    customer_id,
    name,
    preferences->'$.newsletter' AS newsletter,
    preferences->'$.settings.dark_mode' AS dark_mode
FROM customers
WHERE preferences IS NOT NULL;

-- Use ->> operator to get unquoted string value
SELECT 
    customer_id,
    name,
    preferences->>'$.preferred_contact_time' AS contact_time,
    preferences->>'$.settings.currency' AS currency
FROM customers
WHERE preferences IS NOT NULL;

-- Extract array elements
SELECT 
    customer_id,
    name,
    JSON_EXTRACT(preferences, '$.preferred_categories[0]') AS first_category,
    JSON_EXTRACT(preferences, '$.interests[0]') AS first_interest
FROM customers
WHERE preferences IS NOT NULL;

-- ================================================================
-- SECTION 4: JSON SEARCH AND FILTERING
-- ================================================================

-- Find customers who opted into newsletter
SELECT customer_id, name, email
FROM customers
WHERE JSON_EXTRACT(preferences, '$.newsletter') = TRUE;

-- Find customers with specific category preference
SELECT customer_id, name
FROM customers
WHERE JSON_CONTAINS(preferences->'$.preferred_categories', '2');

-- Find customers interested in electronics
SELECT customer_id, name
FROM customers
WHERE JSON_CONTAINS(preferences->'$.interests', '"electronics"');

-- Search for a value in JSON using JSON_SEARCH
SELECT customer_id, name
FROM customers
WHERE JSON_SEARCH(preferences, 'one', 'email') IS NOT NULL;

-- Find customers with dark mode enabled
SELECT customer_id, name
FROM customers
WHERE preferences->>'$.settings.dark_mode' = 'true';

-- ================================================================
-- SECTION 5: MODIFYING JSON DATA
-- ================================================================

-- Set a new JSON value
UPDATE customers
SET preferences = JSON_SET(preferences, '$.loyalty_points', 500)
WHERE customer_id = 1;

-- Insert a new key (only if it doesn't exist)
UPDATE customers
SET preferences = JSON_INSERT(preferences, '$.referral_code', 'REF001')
WHERE customer_id = 1;

-- Replace an existing value (only if key exists)
UPDATE customers
SET preferences = JSON_REPLACE(preferences, '$.newsletter', FALSE)
WHERE customer_id = 1;

-- Remove a key
UPDATE customers
SET preferences = JSON_REMOVE(preferences, '$.temporary_field')
WHERE customer_id = 1;

-- Append to an array
UPDATE customers
SET preferences = JSON_ARRAY_APPEND(
    preferences, 
    '$.preferred_categories', 
    5
)
WHERE customer_id = 1;

-- Insert into an array at specific position
UPDATE customers
SET preferences = JSON_ARRAY_INSERT(
    preferences, 
    '$.preferred_categories[0]', 
    0
)
WHERE customer_id = 1;

-- ================================================================
-- SECTION 6: JSON AGGREGATION
-- ================================================================

-- Aggregate customer data into JSON
SELECT JSON_ARRAYAGG(
    JSON_OBJECT(
        'id', customer_id,
        'name', name,
        'email', email,
        'city', city
    )
) AS customers_json
FROM customers
WHERE city = 'Mumbai';

-- Create JSON object from grouped data
SELECT 
    city,
    JSON_OBJECTAGG(customer_id, name) AS customers_by_id
FROM customers
GROUP BY city;

-- ================================================================
-- SECTION 7: JSON TABLE FUNCTIONS
-- ================================================================

-- Convert JSON array to table rows using JSON_TABLE
SELECT 
    c.customer_id,
    c.name,
    jt.category_id
FROM customers c,
JSON_TABLE(
    c.preferences,
    '$.preferred_categories[*]' 
    COLUMNS (
        category_id INT PATH '$'
    )
) AS jt
WHERE c.preferences IS NOT NULL;

-- More complex JSON_TABLE with nested data
SELECT 
    c.customer_id,
    c.name,
    addr.address_type,
    addr.city AS address_city,
    addr.is_default
FROM customers c,
JSON_TABLE(
    c.preferences,
    '$.address_book[*]' 
    COLUMNS (
        address_type VARCHAR(20) PATH '$.type',
        city VARCHAR(50) PATH '$.city',
        is_default BOOLEAN PATH '$.is_default'
    )
) AS addr
WHERE c.customer_id = 3;

-- ================================================================
-- SECTION 8: JSON UTILITY FUNCTIONS
-- ================================================================

-- Check if valid JSON
SELECT 
    customer_id,
    JSON_VALID(preferences) AS is_valid_json
FROM customers;

-- Get JSON type
SELECT 
    customer_id,
    JSON_TYPE(preferences) AS json_type,
    JSON_TYPE(preferences->'$.newsletter') AS newsletter_type,
    JSON_TYPE(preferences->'$.preferred_categories') AS categories_type
FROM customers
WHERE preferences IS NOT NULL;

-- Get JSON depth
SELECT 
    customer_id,
    JSON_DEPTH(preferences) AS max_depth
FROM customers
WHERE preferences IS NOT NULL;

-- Get JSON length
SELECT 
    customer_id,
    JSON_LENGTH(preferences) AS top_level_keys,
    JSON_LENGTH(preferences->'$.preferred_categories') AS category_count
FROM customers
WHERE preferences IS NOT NULL;

-- Get all keys at top level
SELECT 
    customer_id,
    JSON_KEYS(preferences) AS all_keys
FROM customers
WHERE preferences IS NOT NULL;

-- Pretty print JSON
SELECT 
    customer_id,
    JSON_PRETTY(preferences) AS formatted_json
FROM customers
WHERE customer_id = 1;

-- ================================================================
-- SECTION 9: PRACTICAL EXAMPLES
-- ================================================================

-- Example 1: Store and query product specifications as JSON
ALTER TABLE products ADD COLUMN specifications JSON;

UPDATE products 
SET specifications = JSON_OBJECT(
    'weight', '2.5 kg',
    'dimensions', JSON_OBJECT('length', 35, 'width', 25, 'height', 3),
    'color', 'Silver',
    'warranty_months', 24,
    'features', JSON_ARRAY('Backlit Keyboard', 'Fingerprint Reader', 'USB-C')
)
WHERE product_id = 1;

-- Query products by specifications
SELECT name, price
FROM products
WHERE JSON_EXTRACT(specifications, '$.warranty_months') >= 24;

-- Example 2: Customer activity log
CREATE TABLE IF NOT EXISTS customer_activity_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    activity_type VARCHAR(50),
    activity_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO customer_activity_log (customer_id, activity_type, activity_data)
VALUES (
    1, 
    'product_view', 
    JSON_OBJECT(
        'product_id', 5,
        'product_name', 'Sony Headphones',
        'view_duration_seconds', 45,
        'source', 'search',
        'device', 'mobile'
    )
);

-- Analyze customer activities
SELECT 
    customer_id,
    activity_type,
    activity_data->>'$.product_name' AS product_viewed,
    activity_data->>'$.device' AS device_used,
    created_at
FROM customer_activity_log
WHERE activity_type = 'product_view'
ORDER BY created_at DESC;

-- ================================================================
-- SECTION 10: JSON INDEXING
-- ================================================================

-- Create a generated column for indexing JSON values
ALTER TABLE customers 
ADD COLUMN newsletter_opt_in BOOLEAN 
GENERATED ALWAYS AS (JSON_EXTRACT(preferences, '$.newsletter')) STORED;

-- Create index on generated column
CREATE INDEX idx_newsletter ON customers(newsletter_opt_in);

-- Now queries can use the index
SELECT customer_id, name
FROM customers
WHERE newsletter_opt_in = TRUE;

-- ================================================================
-- END OF JSON FUNCTIONS
-- ================================================================
