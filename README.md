# 🎯 Advanced SQL Project - Retail Sales Analytics

![SQL](https://img.shields.io/badge/SQL-MySQL-blue?style=for-the-badge&logo=mysql)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Concepts](https://img.shields.io/badge/Level-Intermediate%20|%20Advanced-orange?style=for-the-badge)

> 🚀 A comprehensive SQL project demonstrating advanced database concepts, query optimization, and real-world retail analytics scenarios.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Database Schema](#-database-schema)
- [SQL Concepts Covered](#-sql-concepts-covered)
- [Installation & Setup](#-installation--setup)
- [Usage Examples](#-usage-examples)
- [Project Structure](#-project-structure)
- [Sample Queries](#-sample-queries)
- [Performance Optimization](#-performance-optimization)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact](#-contact)

---

## 🎯 Overview

This project is a **comprehensive demonstration of intermediate and advanced SQL concepts** applied to a real-world retail sales management system. It showcases practical implementations of complex queries, stored procedures, triggers, and analytical functions used in modern database applications.

### 🎓 Learning Objectives

- Master **advanced SQL query techniques** for data analysis
- Understand **database design principles** and normalization
- Implement **business logic** using stored procedures and functions
- Utilize **window functions** for complex analytics
- Apply **query optimization** techniques for better performance
- Create **meaningful views** for simplified data access

---

## ✨ Features

### 🏗️ Database Features

- ✅ **Normalized database schema** (3NF) with 10+ related tables
- ✅ **Foreign key constraints** for referential integrity
- ✅ **Indexes** for query optimization
- ✅ **Triggers** for automatic data updates
- ✅ **Stored procedures** for business logic encapsulation
- ✅ **User-defined functions** for reusable calculations
- ✅ **Views** for simplified complex queries

### 📊 Analytics Features

- ✅ **RFM Analysis** (Recency, Frequency, Monetary)
- ✅ **Customer Segmentation** based on purchase behavior
- ✅ **Product Performance Tracking**
- ✅ **Sales Forecasting** using moving averages
- ✅ **Employee Performance Metrics**
- ✅ **Inventory Management** with reorder alerts
- ✅ **Cohort Analysis** for customer retention

---

## 🗃️ Database Schema

### Core Tables

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│   CUSTOMERS     │      │      SALES       │      │    EMPLOYEES    │
├─────────────────┤      ├──────────────────┤      ├─────────────────┤
│ customer_id (PK)│◄────┤ customer_id (FK) │      │ employee_id (PK)│
│ name            │      │ employee_id (FK) │─────►│ name            │
│ email           │      │ sale_date        │      │ position        │
│ tier_id (FK)    │      │ total_amount     │      │ salary          │
└─────────────────┘      └──────────────────┘      └─────────────────┘
                                  │
                                  │
                         ┌────────▼──────────┐
                         │  SALES_DETAILS    │      ┌─────────────────┐
                         ├───────────────────┤      │    PRODUCTS     │
                         │ sale_id (FK)      │      ├─────────────────┤
                         │ product_id (FK)   │─────►│ product_id (PK) │
                         │ quantity          │      │ name            │
                         │ line_total        │      │ category_id (FK)│
                         └───────────────────┘      │ price           │
                                                     │ stock           │
                                                     └─────────────────┘
```

### Supporting Tables

- **categories**: Product categorization
- **customer_tiers**: Loyalty program tiers with discount levels
- **payment_methods**: Supported payment options
- **inventory_transactions**: Stock movement tracking

---

## 🧠 SQL Concepts Covered

### 📚 Intermediate Concepts

| Concept | Description | Example Query |
|---------|-------------|---------------|
| **JOINs** | INNER, LEFT, RIGHT, CROSS, SELF joins | Customer purchase history |
| **Subqueries** | Nested and correlated subqueries | Products above category average |
| **Aggregation** | GROUP BY, HAVING, COUNT, SUM, AVG | Sales summaries |
| **CASE Statements** | Conditional logic in queries | Customer segmentation |
| **Views** | Virtual tables for complex queries | vw_sales_summary |
| **Indexes** | Performance optimization | Composite indexes on sales |

### 🚀 Advanced Concepts

| Concept | Description | Example Query |
|---------|-------------|---------------|
| **Window Functions** | ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD | Product ranking by category |
| **CTEs** | Common Table Expressions, recursive CTEs | Employee hierarchy, spending analysis |
| **ROLLUP/CUBE** | Multi-dimensional aggregation | Sales by city and tier |
| **Stored Procedures** | Reusable SQL code blocks | sp_add_sale, sp_customer_summary |
| **Functions** | User-defined functions | fn_profit_margin, fn_get_customer_tier |
| **Triggers** | Automatic actions on data changes | Update customer spending |
| **Full-Text Search** | Advanced text searching | Product search by name |
| **Query Optimization** | EXPLAIN, index strategies | Optimized sales reports |

---

## 🛠️ Installation & Setup

### Prerequisites

- MySQL Server 8.0 or higher
- MySQL Workbench (recommended) or any SQL client
- Python 3.x (for Jupyter notebook examples)

### Step 1: Clone the Repository

```bash
git clone https://github.com/punit745/SQl_Projects.git
cd SQl_Projects
```

### Step 2: Create the Database

```bash
mysql -u root -p < Advanced_SQL_Queries.sql
```

Or manually in MySQL Workbench:

1. Open MySQL Workbench
2. Create a new connection
3. Open `Advanced_SQL_Queries.sql`
4. Execute the script (sections 1-2 for schema and data)

### Step 3: Verify Installation

```sql
USE retail_sales_advanced;
SHOW TABLES;
SELECT COUNT(*) FROM sales;
```

---

## 💡 Usage Examples

### Basic Queries

```sql
-- Get all sales with customer details
SELECT * FROM vw_sales_summary 
WHERE sale_date >= '2024-01-01'
ORDER BY total_amount DESC;

-- Check product performance
SELECT * FROM vw_product_performance 
WHERE total_revenue > 50000
ORDER BY total_revenue DESC;
```

### Advanced Analytics

```sql
-- Find top customers by spending
WITH customer_spending AS (
    SELECT customer_id, name, lifetime_value
    FROM vw_customer_analytics
    WHERE lifetime_value > 0
)
SELECT * FROM customer_spending
ORDER BY lifetime_value DESC
LIMIT 10;

-- Product ranking within categories
SELECT 
    category_name,
    product_name,
    total_revenue,
    RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rank
FROM vw_product_performance
WHERE total_revenue IS NOT NULL;
```

### Using Stored Procedures

```sql
-- Add a new sale
CALL sp_add_sale(1, 2, 2, 3, 2);

-- Get customer summary
CALL sp_customer_summary(1);
```

---

## 📁 Project Structure

```
SQl_Projects/
│
├── README.md                      # Project documentation (this file)
├── Advanced_SQL_Queries.sql       # Complete advanced SQL implementation
├── Retail_Sale_Project.sql        # Basic schema (original)
├── SQL_Project.ipynb              # Python MySQL integration examples
│
└── (Future additions)
    ├── docs/                      # Additional documentation
    ├── images/                    # Schema diagrams and screenshots
    └── sample_data/               # Additional sample datasets
```

---

## 🔍 Sample Queries

### 1️⃣ Customer Segmentation (RFM Analysis)

```sql
-- Classify customers based on Recency, Frequency, and Monetary value
SELECT 
    customer_id,
    name,
    CASE 
        WHEN rfm_total_score >= 12 THEN 'Champions'
        WHEN rfm_total_score >= 9 THEN 'Loyal Customers'
        WHEN rfm_total_score >= 6 THEN 'Potential'
        ELSE 'At Risk'
    END AS segment
FROM (
    -- RFM calculation query
    -- See Advanced_SQL_Queries.sql Query #18 for full implementation
) rfm_analysis;
```

### 2️⃣ Sales Trends with Moving Averages

```sql
-- Track daily sales with 7-day and 30-day moving averages
SELECT 
    sale_date,
    daily_total,
    AVG(daily_total) OVER (
        ORDER BY sale_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ma_7_day
FROM daily_sales;
```

### 3️⃣ Employee Performance Ranking

```sql
-- Rank employees by total sales revenue
SELECT 
    name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS performance_rank
FROM employee_performance;
```

### 4️⃣ Product Affinity Analysis

```sql
-- Find products frequently bought together
SELECT 
    p1.name AS product_1,
    p2.name AS product_2,
    COUNT(*) AS bought_together_count
FROM sales_details sd1
JOIN sales_details sd2 ON sd1.sale_id = sd2.sale_id
JOIN products p1 ON sd1.product_id = p1.product_id
JOIN products p2 ON sd2.product_id = p2.product_id
WHERE sd1.product_id < sd2.product_id
GROUP BY p1.name, p2.name
ORDER BY bought_together_count DESC;
```

---

## ⚡ Performance Optimization

### Indexing Strategy

```sql
-- Indexes created for optimal query performance
CREATE INDEX idx_sale_date_customer ON sales(sale_date, customer_id);
CREATE INDEX idx_category ON products(category_id);
CREATE INDEX idx_customer_tier ON customers(tier_id);
```

### Query Optimization Tips

1. **Use EXPLAIN** to analyze query execution plans
2. **Create appropriate indexes** on frequently queried columns
3. **Use JOINs instead of subqueries** where possible
4. **Limit result sets** with WHERE clauses and LIMIT
5. **Use covering indexes** to avoid table lookups

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Contribution Ideas

- 📊 Add more sample datasets
- 📈 Create data visualization examples
- 🧪 Add query performance benchmarks
- 📖 Improve documentation
- 🔧 Add more stored procedures/functions

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

**Punit Pal**

- GitHub: [@punit745](https://github.com/punit745)
- Project Link: [https://github.com/punit745/SQl_Projects](https://github.com/punit745/SQl_Projects)

---

## 🙏 Acknowledgments

- MySQL Documentation for comprehensive SQL references
- The SQL community for best practices and optimization techniques
- Various online resources for advanced SQL concepts

---

## 📊 Statistics

- **10+ Database Tables** with proper relationships
- **22+ Advanced Query Examples** covering various concepts
- **5+ Stored Procedures** for business logic
- **3+ Triggers** for automatic data management
- **2+ User-Defined Functions** for calculations
- **5+ Views** for simplified data access

---

<div align="center">

### ⭐ If you find this project helpful, please give it a star!

**Made with ❤️ and SQL**

</div>
