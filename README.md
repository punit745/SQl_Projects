# 🎯 Advanced SQL Project - Retail Sales Analytics

![SQL](https://img.shields.io/badge/SQL-MySQL-blue?style=for-the-badge&logo=mysql)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)
![Level](https://img.shields.io/badge/Level-Intermediate%20%7C%20Advanced-orange?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-3.0-purple?style=for-the-badge)

> 🚀 A comprehensive SQL project demonstrating **50+ advanced database concepts**, query optimization, data warehousing, testing frameworks, and real-world retail analytics scenarios.

---

## 📋 Table of Contents

- [Features](#-features)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [SQL Concepts Covered](#-sql-concepts-covered)
- [Learning Path](#-learning-path)
- [Documentation](#-documentation)
- [Utility Scripts](#-utility-scripts)

---

## ⭐ Features

### Core Features
- ✅ **Complete Database Schema** - Tables, indexes, views, procedures, functions, triggers
- ✅ **20+ Query Files** - From basics to advanced analytics
- ✅ **Data Warehousing** - Star schema, ETL, OLAP queries
- ✅ **Testing Framework** - Unit tests for procedures, triggers, data integrity
- ✅ **Migration System** - Version-controlled schema changes
- ✅ **Performance Monitoring** - Health checks and optimization

### NEW in v3.0
- 🆕 **Query Optimization** - EXPLAIN, profiling, index hints
- 🆕 **Table Partitioning** - Range, list, hash strategies
- 🆕 **API Procedures** - REST-style JSON responses
- 🆕 **Pagination Patterns** - Offset, cursor, keyset
- 🆕 **ML Feature Engineering** - Customer, product features
- 🆕 **A/B Testing Analysis** - Statistical significance
- 🆕 **Funnel Analysis** - Conversion tracking
- 🆕 **Forecasting Queries** - Time series analysis

---

## 📁 Project Structure

```
SQl_Projects/
├── 📂 schema/                    # Database Schema (7 files)
│   ├── 01_create_database.sql    # Database creation
│   ├── 02_create_tables.sql      # Table definitions
│   ├── 03_create_indexes.sql     # Index optimization
│   ├── 04_create_views.sql       # Views & materialized views
│   ├── 05_create_procedures.sql  # Stored procedures (10+)
│   ├── 06_create_functions.sql   # User-defined functions (15+)
│   └── 07_create_triggers.sql    # Triggers & automation
│
├── 📂 queries/                   # SQL Query Examples (20 files)
│   ├── 01_basic_queries.sql      # SELECT, WHERE, GROUP BY
│   ├── 02_joins.sql              # All JOIN types
│   ├── 03_subqueries.sql         # Scalar, correlated subqueries
│   ├── 04_window_functions.sql   # ROW_NUMBER, RANK, LAG, LEAD
│   ├── 05_ctes.sql               # Standard & recursive CTEs
│   ├── 06_set_operations.sql     # UNION, INTERSECT, PIVOT
│   ├── 07_json_functions.sql     # JSON data operations
│   ├── 08_transactions.sql       # ACID, savepoints, locking
│   ├── 09_advanced_analytics.sql # CLV, churn, market basket
│   ├── 10_security_audit.sql     # Users, roles, audit logging
│   ├── 11_query_optimization.sql # 🆕 EXPLAIN, profiling
│   ├── 12_partitioning.sql       # 🆕 Table partitioning
│   ├── 13_api_procedures.sql     # 🆕 REST-style APIs
│   ├── 14_pagination_patterns.sql# 🆕 Cursor/keyset pagination
│   ├── 15_performance_monitoring.sql # 🆕 DB monitoring
│   ├── 16_feature_engineering.sql# 🆕 ML features
│   ├── 17_health_checks.sql      # 🆕 Health diagnostics
│   ├── 18_forecasting.sql        # 🆕 Time series
│   ├── 19_ab_testing.sql         # 🆕 Statistical analysis
│   └── 20_funnel_analysis.sql    # 🆕 Conversion funnels
│
├── 📂 warehouse/                 # 🆕 Data Warehouse (3 files)
│   ├── 01_star_schema.sql        # Dimension & fact tables
│   ├── 02_olap_queries.sql       # OLAP operations
│   └── 03_etl_procedures.sql     # ETL processes
│
├── 📂 tests/                     # 🆕 Testing Framework (3 files)
│   ├── test_procedures.sql       # Procedure unit tests
│   ├── test_triggers.sql         # Trigger tests
│   └── test_data_integrity.sql   # Data quality tests
│
├── 📂 migrations/                # 🆕 Schema Migrations
│   └── v1_to_v2.sql              # Migration scripts
│
├── 📂 data/                      # Data Scripts (3 files)
│   ├── seed_data.sql             # Sample data
│   ├── generate_test_data.sql    # Bulk data generation
│   └── validation_checks.sql     # Data integrity checks
│
├── 📂 scripts/                   # Utility Scripts (5 files)
│   ├── setup_database.bat        # Full setup automation
│   ├── backup_database.bat       # Database backup
│   ├── run_query.bat             # Query execution
│   ├── migrate.bat               # 🆕 Migration runner
│   └── run_tests.bat             # 🆕 Test runner
│
├── 📂 docs/                      # Documentation
└── 📂 notebooks/                 # Jupyter notebooks
```

---

## 🚀 Quick Start

### Prerequisites
- MySQL 8.0+ installed
- MySQL client in PATH

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/punit745/SQl_Projects.git
cd SQl_Projects

# 2. Run the setup script
cd scripts
setup_database.bat

# 3. (Optional) Run migrations for latest features
migrate.bat

# 4. (Optional) Run tests
run_tests.bat
```

### Manual Setup
```sql
-- Execute in order:
source schema/01_create_database.sql
source schema/02_create_tables.sql
source schema/03_create_indexes.sql
source schema/04_create_views.sql
source schema/05_create_procedures.sql
source schema/06_create_functions.sql
source schema/07_create_triggers.sql
source data/seed_data.sql
```

---

## 📚 SQL Concepts Covered

### 📖 Beginner (Files 01-02)
| Concept | File | Topics |
|---------|------|--------|
| Basic Queries | `01_basic_queries.sql` | SELECT, WHERE, ORDER BY, LIMIT, GROUP BY, HAVING |
| Joins | `02_joins.sql` | INNER, LEFT, RIGHT, FULL OUTER, SELF, CROSS JOINs |

### 📗 Intermediate (Files 03-06)
| Concept | File | Topics |
|---------|------|--------|
| Subqueries | `03_subqueries.sql` | Scalar, row, table, correlated, derived tables |
| Window Functions | `04_window_functions.sql` | ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD |
| CTEs | `05_ctes.sql` | Standard CTEs, recursive CTEs, RFM analysis |
| Set Operations | `06_set_operations.sql` | UNION, INTERSECT, EXCEPT, PIVOT, ROLLUP |

### 📕 Advanced (Files 07-10)
| Concept | File | Topics |
|---------|------|--------|
| JSON Functions | `07_json_functions.sql` | JSON_EXTRACT, JSON_SET, indexing, aggregation |
| Transactions | `08_transactions.sql` | ACID, savepoints, isolation levels, error handling |
| Analytics | `09_advanced_analytics.sql` | CLV, seasonality, churn, market basket |
| Security | `10_security_audit.sql` | Users, roles, data masking, GDPR, audit trails |

### 🚀 Expert (Files 11-20)
| Concept | File | Topics |
|---------|------|--------|
| Optimization | `11_query_optimization.sql` | EXPLAIN ANALYZE, index hints, batch processing |
| Partitioning | `12_partitioning.sql` | Range, list, hash, subpartitioning |
| API Procedures | `13_api_procedures.sql` | JSON responses, CRUD operations |
| Pagination | `14_pagination_patterns.sql` | Offset, cursor-based, keyset |
| Monitoring | `15_performance_monitoring.sql` | Slow queries, locks, I/O stats |
| ML Features | `16_feature_engineering.sql` | RFM, time series, product affinity |
| Health Checks | `17_health_checks.sql` | Connection, disk, index health |
| Forecasting | `18_forecasting.sql` | Moving averages, EMA, seasonality |
| A/B Testing | `19_ab_testing.sql` | Statistical significance, Z-test |
| Funnel Analysis | `20_funnel_analysis.sql` | Conversion tracking, drop-off |

### 🏢 Data Warehouse
| Concept | File | Topics |
|---------|------|--------|
| Star Schema | `warehouse/01_star_schema.sql` | Dimension tables, fact tables, SCD Type 2 |
| OLAP Queries | `warehouse/02_olap_queries.sql` | ROLLUP, CUBE, drill-down, slice/dice |
| ETL | `warehouse/03_etl_procedures.sql` | Job tracking, incremental loads |

---

## 🎓 Learning Path

```
BEGINNER                INTERMEDIATE              ADVANCED                  EXPERT
   │                         │                        │                        │
   ▼                         ▼                        ▼                        ▼
┌─────────┐            ┌──────────┐            ┌──────────┐            ┌──────────┐
│ Basic   │───────────▶│ Window   │───────────▶│ Advanced │───────────▶│ Query    │
│ Queries │            │ Functions│            │ Analytics│            │ Optimize │
└─────────┘            └──────────┘            └──────────┘            └──────────┘
     │                      │                       │                        │
     ▼                      ▼                       ▼                        ▼
┌─────────┐            ┌──────────┐            ┌──────────┐            ┌──────────┐
│  JOINs  │───────────▶│   CTEs   │───────────▶│ Security │───────────▶│ Star     │
│         │            │ Recursive│            │ & Audit  │            │ Schema   │
└─────────┘            └──────────┘            └──────────┘            └──────────┘
                            │                       │                        │
                            ▼                       ▼                        ▼
                       ┌──────────┐            ┌──────────┐            ┌──────────┐
                       │Subqueries│───────────▶│JSON/Trans│───────────▶│ ML/API   │
                       │          │            │ actions  │            │ Features │
                       └──────────┘            └──────────┘            └──────────┘
```

---

## 🛠 Utility Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup_database.bat` | Full database setup | `scripts\setup_database.bat` |
| `backup_database.bat` | Create timestamped backup | `scripts\backup_database.bat` |
| `run_query.bat` | Execute SQL file | `scripts\run_query.bat queries\09_advanced_analytics.sql` |
| `migrate.bat` | Run migrations | `scripts\migrate.bat` |
| `run_tests.bat` | Execute test suite | `scripts\run_tests.bat` |

---

## 📊 Database Schema

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  customers  │────▶│    sales    │◀────│  employees  │
└─────────────┘     └─────────────┘     └─────────────┘
      │                    │
      │                    ▼
      │             ┌─────────────┐     ┌─────────────┐
      │             │sales_details│────▶│  products   │
      │             └─────────────┘     └─────────────┘
      │                                       │
      ▼                                       ▼
┌─────────────┐                        ┌─────────────┐
│customer_tiers│                       │ categories  │
└─────────────┘                        └─────────────┘
```

### Core Tables
- `customers` - Customer information with tier and spending history
- `products` - Product catalog with pricing and inventory
- `sales` - Transaction headers
- `sales_details` - Transaction line items
- `employees` - Staff information
- `categories` - Product categories
- `customer_tiers` - Loyalty program tiers

### Audit & Logging
- `audit_log` - Change tracking
- `error_log` - Error capture
- `activity_log` - User activities

---

## 📈 Sample Queries

### Customer Lifetime Value
```sql
CALL sp_customer_lifetime_value();
```

### Sales Dashboard
```sql
CALL api_get_dashboard_summary('2024-01-01', '2024-12-31');
```

### Run Health Check
```sql
CALL run_all_health_checks();
```

### Generate Test Data
```sql
CALL sp_generate_all_test_data(1000, 100, 5000);
```

---

## 📄 Documentation

| Document | Description |
|----------|-------------|
| [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) | Complete schema documentation |
| [SQL_CONCEPTS_GUIDE.md](SQL_CONCEPTS_GUIDE.md) | SQL concepts explained |
| [PRACTICAL_EXAMPLES.md](PRACTICAL_EXAMPLES.md) | Real-world examples |
| [QUICK_START.md](QUICK_START.md) | Getting started guide |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Common issues & solutions |

---

## 🧪 Testing

Run the test suite to validate your setup:

```bash
scripts\run_tests.bat
```

Or manually:
```sql
CALL run_all_tests();
CALL run_all_data_integrity_tests();
CALL run_all_trigger_tests();
```

---

## 📊 Summary

| Category | Count |
|----------|-------|
| Schema Files | 7 |
| Query Files | 20 |
| Warehouse Files | 3 |
| Test Files | 3 |
| Data Files | 3 |
| Utility Scripts | 5 |
| **Total Files** | **41+** |

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

---

## 👤 Author

**Punit**

- GitHub: [@punit745](https://github.com/punit745)

---

⭐ **Star this repository if you found it helpful!**
