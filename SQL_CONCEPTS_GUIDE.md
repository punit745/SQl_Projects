# 📚 SQL Concepts Guide

A comprehensive guide to understanding all the SQL concepts demonstrated in this project.

---

## Table of Contents

1. [Window Functions](#1-window-functions)
2. [Common Table Expressions (CTEs)](#2-common-table-expressions-ctes)
3. [Complex Joins](#3-complex-joins)
4. [Aggregation Functions](#4-aggregation-functions)
5. [Stored Procedures](#5-stored-procedures)
6. [User-Defined Functions](#6-user-defined-functions)
7. [Triggers](#7-triggers)
8. [Views](#8-views)
9. [Indexes](#9-indexes)
10. [Query Optimization](#10-query-optimization)

---

## 1. Window Functions

Window functions perform calculations across a set of rows related to the current row, without collapsing the result set.

### Key Window Functions

#### ROW_NUMBER()
Assigns a unique sequential integer to rows within a partition.

```sql
SELECT 
    product_name,
    category_name,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY price DESC) AS row_num
FROM products p
JOIN categories c ON p.category_id = c.category_id;
```

**Use Case**: Numbering rows within groups (e.g., numbering products within each category)

#### RANK() and DENSE_RANK()
Assigns ranks to rows, with gaps (RANK) or without gaps (DENSE_RANK) for ties.

```sql
SELECT 
    name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS dense_rank
FROM vw_product_performance;
```

**Use Case**: Finding top performers, creating leaderboards

#### LAG() and LEAD()
Access data from previous (LAG) or next (LEAD) rows.

```sql
SELECT 
    sale_date,
    total_amount,
    LAG(total_amount) OVER (ORDER BY sale_date) AS prev_sale,
    LEAD(total_amount) OVER (ORDER BY sale_date) AS next_sale
FROM sales;
```

**Use Case**: Comparing current values with previous/next values, calculating changes

#### Aggregate Window Functions
Running totals, moving averages, etc.

```sql
SELECT 
    sale_date,
    total_amount,
    SUM(total_amount) OVER (ORDER BY sale_date) AS running_total,
    AVG(total_amount) OVER (
        ORDER BY sale_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3
FROM sales;
```

**Use Case**: Cumulative calculations, trend analysis

---

## 2. Common Table Expressions (CTEs)

CTEs create temporary named result sets that can be referenced within a SELECT, INSERT, UPDATE, or DELETE statement.

### Simple CTE

```sql
WITH customer_spending AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spent
    FROM sales
    GROUP BY customer_id
)
SELECT 
    c.name,
    cs.total_spent
FROM customers c
JOIN customer_spending cs ON c.customer_id = cs.customer_id
WHERE cs.total_spent > 50000;
```

**Benefits**:
- Improved readability
- Code reusability within the same query
- Better organization of complex queries

### Recursive CTE

Used for hierarchical data like organizational charts, bill of materials, etc.

```sql
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: top-level managers
    SELECT employee_id, name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive case: employees reporting to managers
    SELECT e.employee_id, e.name, e.manager_id, eh.level + 1
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy;
```

**Use Case**: Organizational hierarchies, category trees, nested comments

---

## 3. Complex Joins

### Self-Join
Joining a table to itself.

```sql
-- Find customers from the same city
SELECT 
    c1.name AS customer1,
    c2.name AS customer2,
    c1.city
FROM customers c1
JOIN customers c2 ON c1.city = c2.city 
WHERE c1.customer_id < c2.customer_id;
```

**Use Case**: Finding relationships within the same table, comparing rows

### Cross Join
Cartesian product of two tables.

```sql
SELECT 
    p.name AS product,
    pm.method_name AS payment_method
FROM products p
CROSS JOIN payment_methods pm;
```

**Use Case**: Generating all possible combinations

### LEFT JOIN with IS NULL
Finding records that don't have matches.

```sql
-- Products that have never been sold
SELECT p.*
FROM products p
LEFT JOIN sales_details sd ON p.product_id = sd.product_id
WHERE sd.product_id IS NULL;
```

**Use Case**: Finding orphan records, missing relationships

---

## 4. Aggregation Functions

### GROUP BY with ROLLUP

Creates subtotals and grand totals.

```sql
SELECT 
    city,
    tier_name,
    COUNT(*) AS customer_count,
    SUM(total_amount) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN customer_tiers ct ON c.tier_id = ct.tier_id
GROUP BY city, tier_name WITH ROLLUP;
```

**Output includes**:
- Detailed rows (city + tier)
- Subtotals for each city (all tiers)
- Grand total (all cities and tiers)

### GROUPING SETS

Specify multiple grouping sets in a single query.

```sql
SELECT 
    category_name,
    payment_method,
    SUM(total_amount) AS revenue
FROM sales_analysis
GROUP BY GROUPING SETS (
    (category_name, payment_method),
    (category_name),
    (payment_method),
    ()
);
```

**Use Case**: Multi-dimensional analysis, OLAP reporting

---

## 5. Stored Procedures

Stored procedures are precompiled SQL code that can be executed repeatedly.

### Benefits
- **Performance**: Compiled once, executed many times
- **Security**: Can grant execute permissions without table access
- **Maintenance**: Business logic in one place
- **Reduced network traffic**: Multiple statements in one call

### Example

```sql
DELIMITER //
CREATE PROCEDURE sp_add_sale(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    
    -- Get product price
    SELECT price INTO v_price 
    FROM products 
    WHERE product_id = p_product_id;
    
    -- Insert sale
    INSERT INTO sales (customer_id, total_amount)
    VALUES (p_customer_id, v_price * p_quantity);
    
    -- Update stock
    UPDATE products 
    SET stock = stock - p_quantity
    WHERE product_id = p_product_id;
END //
DELIMITER ;

-- Usage
CALL sp_add_sale(1, 5, 2);
```

---

## 6. User-Defined Functions

Functions return a single value and can be used in SQL expressions.

### Types
1. **Scalar Functions**: Return a single value
2. **Table Functions**: Return a table (MySQL doesn't support directly)

### Example

```sql
DELIMITER //
CREATE FUNCTION fn_profit_margin(p_product_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_cost DECIMAL(10,2);
    
    SELECT price, cost_price INTO v_price, v_cost
    FROM products
    WHERE product_id = p_product_id;
    
    RETURN ((v_price - v_cost) / v_price) * 100;
END //
DELIMITER ;

-- Usage
SELECT 
    name,
    price,
    fn_profit_margin(product_id) AS margin_pct
FROM products;
```

---

## 7. Triggers

Triggers automatically execute SQL code in response to certain events on a table.

### Types
- **BEFORE INSERT/UPDATE/DELETE**: Execute before the operation
- **AFTER INSERT/UPDATE/DELETE**: Execute after the operation

### Example: Auto-update Customer Spending

```sql
DELIMITER //
CREATE TRIGGER trg_update_customer_spending
AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE customers
    SET total_spent = total_spent + NEW.total_amount,
        last_purchase_date = NEW.sale_date
    WHERE customer_id = NEW.customer_id;
END //
DELIMITER ;
```

### Use Cases
- Audit trails
- Data validation
- Maintaining derived columns
- Enforcing business rules

---

## 8. Views

Views are virtual tables based on the result of a SELECT statement.

### Benefits
- **Simplification**: Hide complex queries
- **Security**: Restrict access to specific columns/rows
- **Consistency**: Ensure consistent data presentation

### Example

```sql
CREATE VIEW vw_sales_summary AS
SELECT 
    s.sale_id,
    c.name AS customer_name,
    s.sale_date,
    s.total_amount,
    ct.tier_name
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN customer_tiers ct ON c.tier_id = ct.tier_id;

-- Usage
SELECT * FROM vw_sales_summary 
WHERE sale_date >= '2024-01-01';
```

### Materialized Views
(Not directly supported in MySQL, but can be simulated with tables and triggers)

---

## 9. Indexes

Indexes improve query performance by creating fast lookup structures.

### Types of Indexes

#### Single-Column Index
```sql
CREATE INDEX idx_customer_email ON customers(email);
```

#### Composite Index
```sql
CREATE INDEX idx_sale_date_customer ON sales(sale_date, customer_id);
```

#### Unique Index
```sql
CREATE UNIQUE INDEX idx_unique_email ON customers(email);
```

#### Full-Text Index
```sql
ALTER TABLE products ADD FULLTEXT INDEX ft_product_name (name);

SELECT * FROM products
WHERE MATCH(name) AGAINST('laptop' IN NATURAL LANGUAGE MODE);
```

### Index Best Practices

✅ **Do Index**:
- Primary keys (automatic)
- Foreign keys
- Columns in WHERE clauses
- Columns in JOIN conditions
- Columns in ORDER BY

❌ **Don't Index**:
- Small tables (< 1000 rows)
- Columns with low cardinality (few unique values)
- Frequently updated columns
- Very large columns (TEXT, BLOB)

---

## 10. Query Optimization

### Use EXPLAIN

```sql
EXPLAIN SELECT 
    c.name,
    s.total_amount
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
WHERE s.sale_date >= '2024-01-01';
```

**Key columns to look at**:
- `type`: Join type (const > eq_ref > ref > range > index > ALL)
- `key`: Which index is used
- `rows`: Estimated rows scanned
- `Extra`: Additional information (Using filesort, Using temporary)

### Optimization Techniques

#### 1. Use Indexes Appropriately
```sql
-- Bad: Function on indexed column
SELECT * FROM customers WHERE UPPER(email) = 'JOHN@EMAIL.COM';

-- Good: Use column directly
SELECT * FROM customers WHERE email = 'john@email.com';
```

#### 2. Limit Result Sets
```sql
-- Use WHERE to filter early
SELECT * FROM sales 
WHERE sale_date >= '2024-01-01' 
LIMIT 100;
```

#### 3. Use JOINs Instead of Subqueries (when possible)
```sql
-- Slower (correlated subquery)
SELECT name, 
    (SELECT AVG(price) FROM products p2 WHERE p2.category_id = p.category_id)
FROM products p;

-- Faster (JOIN with aggregation)
SELECT p.name, avg_price
FROM products p
JOIN (
    SELECT category_id, AVG(price) as avg_price
    FROM products
    GROUP BY category_id
) cat_avg ON p.category_id = cat_avg.category_id;
```

#### 4. Use Covering Indexes
```sql
-- Index includes all columns needed
CREATE INDEX idx_covering ON sales(customer_id, sale_date, total_amount);

SELECT customer_id, sale_date, total_amount
FROM sales
WHERE customer_id = 1;
-- No table lookup needed!
```

#### 5. Avoid SELECT *
```sql
-- Bad
SELECT * FROM sales;

-- Good: Only select needed columns
SELECT sale_id, customer_id, total_amount FROM sales;
```

---

## Performance Metrics

### Query Performance Comparison

| Technique | Without Optimization | With Optimization | Improvement |
|-----------|---------------------|-------------------|-------------|
| Indexed WHERE | 1000ms | 10ms | 100x faster |
| JOIN vs Subquery | 500ms | 50ms | 10x faster |
| Covering Index | 200ms | 20ms | 10x faster |
| LIMIT Result Set | 800ms | 80ms | 10x faster |

---

## Best Practices Summary

### ✅ Do's
- Use indexes on frequently queried columns
- Write specific SELECT statements (avoid SELECT *)
- Use JOINs instead of multiple queries
- Analyze queries with EXPLAIN
- Use appropriate data types
- Normalize your database design
- Use stored procedures for complex business logic
- Document your code with comments

### ❌ Don'ts
- Don't use functions on indexed columns in WHERE
- Don't create too many indexes (slows INSERT/UPDATE)
- Don't use SELECT * in production code
- Don't ignore query execution plans
- Don't store calculated values that can be derived
- Don't over-normalize (sometimes denormalization helps)

---

## Additional Resources

### Recommended Reading
- MySQL Official Documentation
- High Performance MySQL (Book)
- SQL Antipatterns (Book)

### Online Tools
- MySQL Workbench Query Profiler
- EXPLAIN Analyzer
- Index Advisor Tools

---

<div align="center">

**Happy Learning! 🎓**

*Master these concepts through practice and experimentation*

</div>
