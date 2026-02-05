# 🎯 Advanced SQL Project - Retail Sales Analytics

![SQL](https://img.shields.io/badge/SQL-MySQL-blue?style=for-the-badge&logo=mysql)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate%20%7C%20Advanced-orange?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-2.0-purple?style=for-the-badge)

> 🚀 A comprehensive SQL project demonstrating advanced database concepts, query optimization, and real-world retail analytics scenarios.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Project Structure](#-project-structure)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [SQL Concepts Covered](#-sql-concepts-covered)
- [Schema Design](#-schema-design)
- [Usage Examples](#-usage-examples)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

This project is a complete retail sales analytics database system designed to demonstrate a wide range of SQL concepts from basic to advanced. It includes:

- **Complete database schema** with proper normalization and relationships
- **Stored procedures and functions** for business logic
- **Triggers** for data integrity and audit logging
- **Views** for simplified data access
- **Advanced analytical queries** including CLV, churn prediction, and market basket analysis
- **Security implementation** with user management and data masking
- **Performance optimization** with proper indexing

---

## 📁 Project Structure

```
SQl_Projects/
├── 📂 schema/                    # Database schema files
│   ├── 01_create_database.sql    # Database creation
│   ├── 02_create_tables.sql      # Table definitions
│   ├── 03_create_indexes.sql     # Performance indexes
│   ├── 04_create_views.sql       # Data views
│   ├── 05_create_procedures.sql  # Stored procedures
│   ├── 06_create_functions.sql   # User-defined functions
│   └── 07_create_triggers.sql    # Automatic triggers
│
├── 📂 queries/                   # SQL query examples
│   ├── 07_json_functions.sql     # JSON operations in MySQL
│   ├── 08_transactions.sql       # Transaction management
│   ├── 09_advanced_analytics.sql # CLV, churn, market basket
│   └── 10_security_audit.sql     # Security and auditing
│
├── 📂 data/                      # Data management
│   ├── seed_data.sql             # Sample data
│   ├── generate_test_data.sql    # Bulk test data generation
│   └── validation_checks.sql     # Data quality checks
│
├── 📂 scripts/                   # Utility scripts
│   ├── setup_database.bat        # Windows setup script
│   ├── backup_database.bat       # Backup utility
│   └── run_query.bat             # Query runner
│
├── 📂 docs/                      # Documentation
├── 📂 notebooks/                 # Jupyter notebooks
│
├── 📄 Advanced_SQL_Queries.sql   # Legacy comprehensive queries
├── 📄 Retail_Sale_Project.sql    # Basic SQL examples
├── 📄 SQL_Project.ipynb          # Jupyter notebook integration
│
├── 📄 README.md                  # This file
├── 📄 DATABASE_SCHEMA.md         # Schema documentation
├── 📄 SQL_CONCEPTS_GUIDE.md      # SQL concepts reference
├── 📄 PRACTICAL_EXAMPLES.md      # Real-world examples
├── 📄 QUICK_START.md             # Quick start guide
└── 📄 TROUBLESHOOTING.md         # Common issues and solutions
```

---

## ✨ Features

### Core Features
| Feature | Description |
|---------|-------------|
| 🏗️ **Modular Schema** | Organized schema files for easy maintenance |
| 📊 **Analytics Queries** | CLV, seasonality, churn, market basket analysis |
| 🔐 **Security** | User management, role-based access, data masking |
| 📝 **Audit Logging** | Complete audit trail for compliance |
| ⚡ **Performance** | Optimized indexes and query patterns |
| 🧪 **Test Data** | Scripts to generate realistic test data |

### SQL Concepts Covered

#### Basic Concepts
- SELECT, INSERT, UPDATE, DELETE
- WHERE, ORDER BY, GROUP BY, HAVING
- JOINs (INNER, LEFT, RIGHT, FULL)
- Aggregations (SUM, COUNT, AVG, MIN, MAX)

#### Intermediate Concepts
- Subqueries and Correlated Subqueries
- Window Functions (ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD)
- Common Table Expressions (CTEs)
- CASE Statements and Conditional Logic
- String and Date Functions

#### Advanced Concepts
- Recursive CTEs (Hierarchical Data)
- Stored Procedures with Error Handling
- User-Defined Functions
- Triggers (BEFORE/AFTER INSERT/UPDATE/DELETE)
- Transactions and ACID Properties
- JSON Functions and Operations
- Dynamic SQL (PREPARE, EXECUTE)
- Security and User Management
- Performance Optimization

---

## 🚀 Quick Start

### Prerequisites
- MySQL 8.0 or higher
- MySQL Workbench (recommended) or any SQL client
- Git (to clone the repository)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/SQL_Projects.git
   cd SQL_Projects
   ```

2. **Run the setup script** (Windows)
   ```batch
   cd scripts
   setup_database.bat
   ```

   Or manually run the schema files in order:
   ```sql
   SOURCE schema/01_create_database.sql;
   SOURCE schema/02_create_tables.sql;
   SOURCE schema/03_create_indexes.sql;
   SOURCE schema/04_create_views.sql;
   SOURCE schema/05_create_procedures.sql;
   SOURCE schema/06_create_functions.sql;
   SOURCE schema/07_create_triggers.sql;
   SOURCE data/seed_data.sql;
   ```

3. **Verify installation**
   ```sql
   USE retail_sales_advanced;
   SHOW TABLES;
   ```

---

## 📊 Schema Design

### Entity Relationship Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  customer_tiers │     │   categories    │     │ payment_methods │
│     (lookup)    │     │    (lookup)     │     │    (lookup)     │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │ 1:N                   │ 1:N                   │ 1:N
         ▼                       ▼                       │
┌─────────────────┐     ┌─────────────────┐              │
│    customers    │     │    products     │              │
│  (core entity)  │     │  (core entity)  │              │
└────────┬────────┘     └────────┬────────┘              │
         │                       │                       │
         │ 1:N                   │ 1:N                   │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────┐
│                       sales                              │
│                  (transaction header)                    │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ 1:N
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   sales_details                          │
│                 (transaction lines)                      │
└─────────────────────────────────────────────────────────┘
```

### Core Tables
| Table | Description |
|-------|-------------|
| `customers` | Customer information with tier assignment |
| `products` | Product catalog with pricing and inventory |
| `sales` | Sales transaction headers |
| `sales_details` | Line items for each sale |
| `employees` | Staff information with hierarchy |
| `categories` | Product categorization |
| `customer_tiers` | Loyalty program tiers |
| `payment_methods` | Supported payment options |

### Support Tables
| Table | Description |
|-------|-------------|
| `inventory_transactions` | Stock movement tracking |
| `audit_log` | Data change audit trail |
| `system_logs` | Application event logging |

---

## 📖 Usage Examples

### Basic Query - Top Customers
```sql
SELECT customer_id, name, total_spent
FROM customers
ORDER BY total_spent DESC
LIMIT 10;
```

### Using Views
```sql
-- Daily sales summary
SELECT * FROM vw_daily_sales
WHERE sale_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY);

-- Product performance
SELECT * FROM vw_product_performance
ORDER BY total_revenue DESC;
```

### Calling Stored Procedures
```sql
-- Get customer summary
CALL sp_customer_summary(1);

-- Generate sales report
CALL sp_sales_report('2024-01-01', '2024-12-31', 'monthly');

-- Inventory alerts
CALL sp_inventory_alerts();
```

### Using Functions
```sql
-- Calculate customer health score
SELECT 
    customer_id,
    name,
    fn_customer_health_score(customer_id) AS health_score,
    fn_customer_segment(customer_id) AS segment
FROM customers;

-- Mask sensitive data
SELECT 
    fn_mask_email(email) AS masked_email,
    fn_mask_phone(phone) AS masked_phone
FROM customers;
```

### Advanced Analytics
```sql
-- Run CLV analysis
-- See queries/09_advanced_analytics.sql for full queries

-- Customer Lifetime Value
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        COUNT(s.sale_id) AS total_orders,
        SUM(s.total_amount) AS total_revenue,
        AVG(s.total_amount) AS avg_order_value
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    WHERE s.status = 'completed'
    GROUP BY c.customer_id
)
SELECT * FROM customer_metrics
ORDER BY total_revenue DESC;
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Complete schema documentation |
| [SQL_CONCEPTS_GUIDE.md](SQL_CONCEPTS_GUIDE.md) | SQL concepts reference |
| [PRACTICAL_EXAMPLES.md](PRACTICAL_EXAMPLES.md) | Real-world query examples |
| [QUICK_START.md](QUICK_START.md) | Getting started guide |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues and solutions |

---

## 🧪 Testing

### Generate Test Data
```sql
-- Generate 1000 customers, 100 products, 5000 sales
CALL sp_generate_all_test_data(1000, 100, 5000);
```

### Run Data Validation
```sql
-- Check data integrity
CALL sp_run_all_validations();
```

### Clean Up Test Data
```sql
CALL sp_cleanup_test_data();
```

---

## 🔧 Utility Scripts

### Windows Scripts
```batch
# Set up the database
scripts\setup_database.bat

# Backup the database
scripts\backup_database.bat

# Run a query file
scripts\run_query.bat queries\09_advanced_analytics.sql
```

---

## 🎓 Learning Path

### Beginner Track
1. Start with `Retail_Sale_Project.sql` for basic concepts
2. Review `SQL_CONCEPTS_GUIDE.md`
3. Practice with sample queries in `PRACTICAL_EXAMPLES.md`

### Intermediate Track
1. Study `schema/04_create_views.sql` for view creation
2. Explore `queries/07_json_functions.sql`
3. Practice window functions and CTEs

### Advanced Track
1. Learn stored procedures in `schema/05_create_procedures.sql`
2. Understand transactions in `queries/08_transactions.sql`
3. Master analytics in `queries/09_advanced_analytics.sql`
4. Implement security from `queries/10_security_audit.sql`

---

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- MySQL Documentation
- SQL Performance Explained by Markus Winand
- Real-world retail analytics patterns

---

<div align="center">

**Made with ❤️ for SQL learners**

[⬆ Back to Top](#-advanced-sql-project---retail-sales-analytics)

</div>
