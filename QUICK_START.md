# 🚀 Quick Start Guide

Get up and running with the Advanced SQL Project in 5 minutes!

---

## Prerequisites Check

Before you begin, ensure you have:

- [ ] MySQL Server 8.0+ installed
- [ ] MySQL Workbench or any SQL client
- [ ] Basic understanding of SQL

---

## Step-by-Step Setup

### Step 1: Install MySQL (if not already installed)

#### Windows
1. Download MySQL Installer from [mysql.com](https://dev.mysql.com/downloads/installer/)
2. Run installer and select "MySQL Server" and "MySQL Workbench"
3. Follow the installation wizard
4. Set root password during installation

#### macOS
```bash
brew install mysql
brew services start mysql
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql
```

### Step 2: Clone the Repository

```bash
git clone https://github.com/punit745/SQl_Projects.git
cd SQl_Projects
```

### Step 3: Load the Database

#### Option A: Using Command Line
```bash
mysql -u root -p < Advanced_SQL_Queries.sql
```

#### Option B: Using MySQL Workbench
1. Open MySQL Workbench
2. Connect to your MySQL server
3. File → Open SQL Script → Select `Advanced_SQL_Queries.sql`
4. Execute the script (Lightning bolt icon or Ctrl+Shift+Enter)

### Step 4: Verify Installation

```sql
-- Connect to the database
USE retail_sales_advanced;

-- Check tables
SHOW TABLES;

-- Expected output: 10 tables
-- categories, customer_tiers, customers, employees, 
-- inventory_transactions, payment_methods, products, 
-- sales, sales_details

-- Check sample data
SELECT COUNT(*) FROM sales;  -- Should return 10
SELECT COUNT(*) FROM customers;  -- Should return 8
SELECT COUNT(*) FROM products;  -- Should return 10
```

---

## Quick Tour

### 1. View Sample Sales Data

```sql
SELECT * FROM vw_sales_summary
ORDER BY sale_date DESC
LIMIT 10;
```

### 2. Check Product Performance

```sql
SELECT 
    product_name,
    category_name,
    total_quantity_sold,
    total_revenue
FROM vw_product_performance
WHERE total_revenue IS NOT NULL
ORDER BY total_revenue DESC;
```

### 3. Analyze Customer Segments

```sql
SELECT 
    customer_id,
    name,
    tier_name,
    lifetime_value,
    total_orders
FROM vw_customer_analytics
ORDER BY lifetime_value DESC;
```

### 4. Test a Stored Procedure

```sql
-- Get summary for customer ID 1
CALL sp_customer_summary(1);
```

### 5. Try a Window Function

```sql
-- Rank products by revenue within each category
SELECT 
    category_name,
    product_name,
    total_revenue,
    RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rank
FROM vw_product_performance
WHERE total_revenue IS NOT NULL
ORDER BY category_name, rank;
```

---

## Common Operations

### Adding New Data

#### Add a New Customer
```sql
INSERT INTO customers (name, email, phone, city, state, tier_id)
VALUES ('New Customer', 'new@email.com', '9999999999', 'Mumbai', 'Maharashtra', 1);
```

#### Add a New Product
```sql
INSERT INTO products (name, category_id, price, cost_price, stock, reorder_level)
VALUES ('New Laptop Model', 2, 95000.00, 78000.00, 15, 5);
```

#### Create a Sale (using stored procedure)
```sql
CALL sp_add_sale(
    1,  -- customer_id
    2,  -- employee_id
    2,  -- payment_method_id (Credit Card)
    3,  -- product_id
    1   -- quantity
);
```

### Querying Data

#### Find Top Selling Products
```sql
SELECT 
    product_name,
    total_quantity_sold,
    total_revenue
FROM vw_product_performance
WHERE total_quantity_sold IS NOT NULL
ORDER BY total_quantity_sold DESC
LIMIT 5;
```

#### Customer Purchase History
```sql
SELECT 
    c.name,
    s.sale_date,
    s.total_amount,
    pm.method_name
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN payment_methods pm ON s.payment_method_id = pm.payment_method_id
WHERE c.customer_id = 1
ORDER BY s.sale_date DESC;
```

---

## Project Structure Overview

```
SQl_Projects/
│
├── README.md                      # Main documentation with badges and features
├── QUICK_START.md                 # This file - getting started guide
├── SQL_CONCEPTS_GUIDE.md          # Detailed explanation of SQL concepts
├── Advanced_SQL_Queries.sql       # Complete database with advanced queries
├── Retail_Sale_Project.sql        # Original basic schema
└── SQL_Project.ipynb              # Python integration examples
```

---

## What to Explore Next?

### For Beginners
1. ✅ Review the basic schema in `Retail_Sale_Project.sql`
2. ✅ Practice SELECT queries on the views
3. ✅ Try simple JOINs and WHERE clauses
4. ✅ Experiment with GROUP BY and aggregation

### For Intermediate Users
1. ✅ Study the window functions (Section 4 in Advanced_SQL_Queries.sql)
2. ✅ Practice CTEs (Section 5)
3. ✅ Understand the stored procedures (Section 10)
4. ✅ Try creating your own queries

### For Advanced Users
1. ✅ Analyze the query execution plans with EXPLAIN
2. ✅ Optimize existing queries
3. ✅ Create your own stored procedures and functions
4. ✅ Implement additional business logic with triggers
5. ✅ Design and add new features to the schema

---

## Troubleshooting

### Issue: Can't connect to MySQL server

**Solution:**
```bash
# Check if MySQL is running
# Windows
services.msc  # Look for MySQL service

# macOS
brew services list

# Linux
sudo systemctl status mysql
```

### Issue: Access denied for user 'root'

**Solution:**
```bash
# Reset root password (Linux/macOS)
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'your_new_password';
FLUSH PRIVILEGES;
```

### Issue: Database already exists

**Solution:**
```sql
-- Drop and recreate
DROP DATABASE IF EXISTS retail_sales_advanced;
-- Then run the script again
```

### Issue: Syntax errors when running script

**Solution:**
- Ensure you're using MySQL 8.0+
- Check DELIMITER settings in your SQL client
- Run sections separately if needed

---

## Learning Path

### Week 1: Foundations
- [ ] Set up the database
- [ ] Understand the schema
- [ ] Practice basic SELECT queries
- [ ] Learn JOINs with the views

### Week 2: Intermediate Concepts
- [ ] Master GROUP BY and aggregation
- [ ] Practice subqueries
- [ ] Understand CASE statements
- [ ] Work with date and string functions

### Week 3: Advanced Concepts
- [ ] Learn window functions
- [ ] Practice CTEs
- [ ] Understand stored procedures
- [ ] Explore triggers and functions

### Week 4: Optimization
- [ ] Use EXPLAIN for query analysis
- [ ] Create and test indexes
- [ ] Optimize slow queries
- [ ] Design new features

---

## Resources

### Documentation
- 📖 [MySQL Official Documentation](https://dev.mysql.com/doc/)
- 📖 [SQL_CONCEPTS_GUIDE.md](SQL_CONCEPTS_GUIDE.md) - In this repository

### Practice
- 💻 Try all queries in `Advanced_SQL_Queries.sql`
- 💻 Modify queries to answer different business questions
- 💻 Create your own sample data

### Community
- 🌐 Stack Overflow - [mysql] tag
- 🌐 MySQL Community Forums
- 🌐 Reddit - r/mysql

---

## Next Steps

1. ✅ **Explore the README.md** for a complete overview
2. ✅ **Read SQL_CONCEPTS_GUIDE.md** for detailed concept explanations
3. ✅ **Run queries from Advanced_SQL_Queries.sql** sections 1-22
4. ✅ **Experiment** with your own queries
5. ✅ **Share** your findings or contribute back!

---

## Getting Help

### Found a bug or have a question?
- Open an issue on [GitHub](https://github.com/punit745/SQl_Projects/issues)
- Check existing issues for solutions

### Want to contribute?
- See [Contributing Guidelines](README.md#-contributing) in README.md
- Fork the repository and submit a pull request

---

<div align="center">

### 🎉 You're all set! Happy querying! 🎉

**Need help? Check the [SQL_CONCEPTS_GUIDE.md](SQL_CONCEPTS_GUIDE.md) for detailed explanations**

</div>
