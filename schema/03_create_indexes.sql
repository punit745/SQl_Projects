-- ================================================================
-- INDEX CREATION SCRIPT
-- Creates all indexes for performance optimization
-- Run after: 02_create_tables.sql
-- ================================================================

USE retail_sales_advanced;

-- ================================================================
-- PRODUCTS TABLE INDEXES
-- ================================================================

-- Index for category lookups
CREATE INDEX idx_products_category ON products(category_id);

-- Index for price range queries
CREATE INDEX idx_products_price ON products(price);

-- Index for active products
CREATE INDEX idx_products_active ON products(is_active);

-- Composite index for category + price filtering
CREATE INDEX idx_products_category_price ON products(category_id, price);

-- Full-text search index for product name and description
ALTER TABLE products ADD FULLTEXT INDEX ft_products_search (name, description);

-- ================================================================
-- CUSTOMERS TABLE INDEXES
-- ================================================================

-- Index for email lookups (unique already creates index, but explicit for clarity)
CREATE INDEX idx_customers_email ON customers(email);

-- Index for tier-based queries
CREATE INDEX idx_customers_tier ON customers(tier_id);

-- Index for city/state based queries
CREATE INDEX idx_customers_location ON customers(city, state);

-- Index for registration date analysis
CREATE INDEX idx_customers_registration ON customers(registration_date);

-- Index for last purchase date (recency analysis)
CREATE INDEX idx_customers_last_purchase ON customers(last_purchase_date);

-- Composite index for active customers by tier
CREATE INDEX idx_customers_active_tier ON customers(is_active, tier_id);

-- ================================================================
-- SALES TABLE INDEXES
-- ================================================================

-- Index for customer sales history
CREATE INDEX idx_sales_customer ON sales(customer_id);

-- Index for date-based queries
CREATE INDEX idx_sales_date ON sales(sale_date);

-- Index for employee performance queries
CREATE INDEX idx_sales_employee ON sales(employee_id);

-- Index for status filtering
CREATE INDEX idx_sales_status ON sales(status);

-- Composite index for date range + customer queries
CREATE INDEX idx_sales_date_customer ON sales(sale_date, customer_id);

-- Composite index for date + status (common filter combination)
CREATE INDEX idx_sales_date_status ON sales(sale_date, status);

-- ================================================================
-- SALES_DETAILS TABLE INDEXES
-- ================================================================

-- Index for sale lookups
CREATE INDEX idx_sales_details_sale ON sales_details(sale_id);

-- Index for product analysis
CREATE INDEX idx_sales_details_product ON sales_details(product_id);

-- Composite index for product + quantity analysis
CREATE INDEX idx_sales_details_product_qty ON sales_details(product_id, quantity);

-- ================================================================
-- INVENTORY TRANSACTIONS TABLE INDEXES
-- ================================================================

-- Index for product inventory lookups
CREATE INDEX idx_inventory_product ON inventory_transactions(product_id);

-- Index for transaction type filtering
CREATE INDEX idx_inventory_type ON inventory_transactions(transaction_type);

-- Index for date-based inventory analysis
CREATE INDEX idx_inventory_date ON inventory_transactions(transaction_date);

-- Composite index for product + date queries
CREATE INDEX idx_inventory_product_date ON inventory_transactions(product_id, transaction_date);

-- ================================================================
-- EMPLOYEES TABLE INDEXES
-- ================================================================

-- Index for manager hierarchy queries
CREATE INDEX idx_employees_manager ON employees(manager_id);

-- Index for department queries
CREATE INDEX idx_employees_department ON employees(department);

-- Index for hire date analysis
CREATE INDEX idx_employees_hire_date ON employees(hire_date);

-- ================================================================
-- AUDIT LOG TABLE INDEXES
-- ================================================================

-- Index for table-specific audit queries
CREATE INDEX idx_audit_table ON audit_log(table_name);

-- Index for date range queries
CREATE INDEX idx_audit_date ON audit_log(changed_at);

-- Composite index for table + action filtering
CREATE INDEX idx_audit_table_action ON audit_log(table_name, action_type);

-- ================================================================
-- SYSTEM LOGS TABLE INDEXES
-- ================================================================

-- Index for log level filtering
CREATE INDEX idx_logs_level ON system_logs(log_level);

-- Index for date-based log queries
CREATE INDEX idx_logs_date ON system_logs(created_at);

-- ================================================================
-- VERIFICATION
-- ================================================================

-- Show all indexes for verification
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    INDEX_TYPE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'retail_sales_advanced'
ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

SELECT 'All indexes created successfully!' AS status;
