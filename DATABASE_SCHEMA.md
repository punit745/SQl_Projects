# 📊 Database Schema Documentation

## Entity Relationship Diagram (ERD)

### Complete Schema Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RETAIL SALES DATABASE SCHEMA                          │
│                         retail_sales_advanced                                │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
│   CATEGORIES     │           │  CUSTOMER_TIERS  │           │    EMPLOYEES     │
├──────────────────┤           ├──────────────────┤           ├──────────────────┤
│• category_id (PK)│◄──┐       │• tier_id (PK)    │◄──┐       │• employee_id (PK)│
│  category_name   │   │       │  tier_name       │   │       │  name            │
│  description     │   │       │  min_purchases   │   │       │  email           │
│  created_at      │   │       │  discount_%      │   │       │  position        │
└──────────────────┘   │       └──────────────────┘   │       │  hire_date       │
                       │                               │       │  salary          │
                       │                               │       │  manager_id (FK) │──┐
┌──────────────────┐   │       ┌──────────────────┐   │       └──────────────────┘  │
│    PRODUCTS      │   │       │    CUSTOMERS     │   │                             │
├──────────────────┤   │       ├──────────────────┤   │                             │
│• product_id (PK) │   │       │• customer_id (PK)│   │                             │
│  name            │   │       │  name            │   │                             │
│  category_id (FK)│───┘       │  email           │   │                             │
│  price           │           │  phone           │   │                             │
│  cost_price      │           │  address         │   │                             │
│  stock           │           │  city            │   │                             │
│  reorder_level   │           │  state           │   │                             │
│  created_at      │           │  zip_code        │   │                             │
│  updated_at      │           │  tier_id (FK)    │───┘                             │
└──────────────────┘           │  registration    │                                 │
        │                      │  last_purchase   │                                 │
        │                      │  total_spent     │                                 │
        │                      └──────────────────┘                                 │
        │                               │                                            │
        │                               │                                            │
        │                      ┌────────▼──────────┐                                │
        │                      │      SALES        │      ┌──────────────────┐      │
        │                      ├───────────────────┤      │ PAYMENT_METHODS  │      │
        │                      │• sale_id (PK)     │      ├──────────────────┤      │
        │                      │  customer_id (FK) │──┐   │• payment_id (PK) │      │
        │                      │  employee_id (FK) │──┼───│  method_name     │◄─────┼──┐
        │                      │  sale_date        │  │   │  is_active       │      │  │
        │                      │  payment_id (FK)  │──┘   └──────────────────┘      │  │
        │                      │  subtotal         │                                 │  │
        │                      │  discount_amount  │                                 │  │
        │                      │  tax_amount       │                                 │  │
        │                      │  total_amount     │                                 │  │
        │                      │  status           │                                 │  │
        │                      └───────────────────┘                                 │  │
        │                               │                                            │  │
        │                               │                                            │  │
        │                      ┌────────▼──────────┐                                │  │
        │                      │  SALES_DETAILS    │                                │  │
        │                      ├───────────────────┤                                │  │
        │                      │• sale_detail_id   │                                │  │
        │                      │  sale_id (FK)     │                                │  │
        │                      │  product_id (FK)  │◄───────────────────────────────┘  │
        │                      │  quantity         │                                   │
        │                      │  unit_price       │                                   │
        │                      │  discount         │                                   │
        │                      │  line_total       │                                   │
        │                      └───────────────────┘                                   │
        │                                                                               │
        │                      ┌───────────────────┐                                   │
        │                      │ INVENTORY_TRANS   │                                   │
        └──────────────────────┤───────────────────┤                                   │
                               │• transaction_id   │                                   │
                               │  product_id (FK)  │                                   │
                               │  trans_type       │                                   │
                               │  quantity         │                                   │
                               │  trans_date       │                                   │
                               │  notes            │                                   │
                               └───────────────────┘                                   │
                                                                                       │
                                                                                       │
              ┌────────────────────────────────────────────────────────────────────────┘
              │ Self-referencing FK: manager_id references employee_id
              └─ Represents organizational hierarchy

Legend:
• = Primary Key
FK = Foreign Key
───► = One-to-Many Relationship
```

---

## Table Descriptions

### Core Business Tables

#### 1. PRODUCTS
**Purpose**: Store product catalog information

**Columns**:
- `product_id` (PK): Unique identifier
- `name`: Product name
- `category_id` (FK): References categories
- `price`: Selling price
- `cost_price`: Purchase/manufacturing cost
- `stock`: Current inventory level
- `reorder_level`: Minimum stock before reordering

**Relationships**:
- Belongs to one CATEGORY
- Has many SALES_DETAILS
- Has many INVENTORY_TRANSACTIONS

#### 2. CUSTOMERS
**Purpose**: Store customer information and contact details

**Columns**:
- `customer_id` (PK): Unique identifier
- `name`: Customer full name
- `email`: Email address (unique)
- `tier_id` (FK): References customer_tiers
- `total_spent`: Cumulative spending (auto-updated)

**Relationships**:
- Has one CUSTOMER_TIER
- Has many SALES

#### 3. SALES
**Purpose**: Store sales transaction headers

**Columns**:
- `sale_id` (PK): Unique identifier
- `customer_id` (FK): Who made the purchase
- `employee_id` (FK): Who processed the sale
- `payment_method_id` (FK): How payment was made
- `status`: Order status (pending, completed, cancelled, refunded)

**Relationships**:
- Belongs to one CUSTOMER
- Belongs to one EMPLOYEE
- Belongs to one PAYMENT_METHOD
- Has many SALES_DETAILS

#### 4. SALES_DETAILS
**Purpose**: Store individual line items for each sale

**Columns**:
- `sale_detail_id` (PK): Unique identifier
- `sale_id` (FK): References parent sale
- `product_id` (FK): Which product was sold
- `quantity`: How many units
- `line_total`: Calculated total for this line

**Relationships**:
- Belongs to one SALE
- Belongs to one PRODUCT

### Supporting Tables

#### 5. CATEGORIES
**Purpose**: Organize products into groups

**Columns**:
- `category_id` (PK): Unique identifier
- `category_name`: Category name
- `description`: Category description

**Relationships**:
- Has many PRODUCTS

#### 6. CUSTOMER_TIERS
**Purpose**: Define customer loyalty levels

**Columns**:
- `tier_id` (PK): Unique identifier
- `tier_name`: Tier name (Bronze, Silver, Gold, Platinum)
- `min_purchases`: Minimum spending to qualify
- `discount_percentage`: Automatic discount for this tier

**Relationships**:
- Has many CUSTOMERS

#### 7. EMPLOYEES
**Purpose**: Store employee information

**Columns**:
- `employee_id` (PK): Unique identifier
- `manager_id` (FK): Self-referencing (organizational hierarchy)
- `position`: Job title
- `salary`: Base salary

**Relationships**:
- Has many SALES (as sales associate)
- Has one EMPLOYEE (as manager)
- Has many EMPLOYEES (as reports)

#### 8. PAYMENT_METHODS
**Purpose**: Available payment options

**Columns**:
- `payment_method_id` (PK): Unique identifier
- `method_name`: Payment method name
- `is_active`: Whether method is currently available

**Relationships**:
- Has many SALES

#### 9. INVENTORY_TRANSACTIONS
**Purpose**: Track all inventory movements

**Columns**:
- `transaction_id` (PK): Unique identifier
- `product_id` (FK): Which product
- `transaction_type`: Type (purchase, sale, adjustment, return)
- `quantity`: Amount (positive or negative)

**Relationships**:
- Belongs to one PRODUCT

---

## Indexes

### Performance Indexes

```sql
-- Customer indexes
CREATE INDEX idx_email ON customers(email);
CREATE INDEX idx_tier ON customers(tier_id);

-- Product indexes
CREATE INDEX idx_category ON products(category_id);
CREATE INDEX idx_price ON products(price);

-- Sales indexes
CREATE INDEX idx_customer ON sales(customer_id);
CREATE INDEX idx_date ON sales(sale_date);
CREATE INDEX idx_status ON sales(status);
CREATE INDEX idx_sale_date_customer ON sales(sale_date, customer_id);

-- Sales details indexes
CREATE INDEX idx_sale ON sales_details(sale_id);
CREATE INDEX idx_product ON sales_details(product_id);
```

---

## Foreign Key Constraints

### Referential Integrity Rules

1. **ON DELETE CASCADE**
   - `sales_details.sale_id` → `sales.sale_id`
   - When a sale is deleted, all its details are deleted too

2. **ON DELETE RESTRICT** (default)
   - Cannot delete a product if it has sales records
   - Cannot delete a customer if they have orders

3. **Self-Referencing**
   - `employees.manager_id` → `employees.employee_id`
   - Allows organizational hierarchy

---

## Database Views

### 1. vw_sales_summary
**Purpose**: Simplified sales data with customer details

```sql
SELECT sale_id, customer_name, sale_date, total_amount, tier_name
FROM sales JOIN customers JOIN customer_tiers
```

### 2. vw_product_performance
**Purpose**: Product sales analytics

```sql
SELECT product_name, category, times_sold, total_revenue
FROM products JOIN sales_details
GROUP BY product_id
```

### 3. vw_customer_analytics
**Purpose**: Customer lifetime value and metrics

```sql
SELECT customer_name, total_orders, lifetime_value, last_purchase
FROM customers JOIN sales
GROUP BY customer_id
```

---

## Triggers

### Automatic Data Updates

1. **trg_update_customer_spending**
   - Fires: AFTER INSERT on sales
   - Action: Updates customer.total_spent

2. **trg_record_sale_inventory**
   - Fires: AFTER INSERT on sales_details
   - Action: Creates inventory transaction record

3. **trg_prevent_product_deletion**
   - Fires: BEFORE DELETE on products
   - Action: Prevents deletion if product has sales

---

## Data Flow

### Sale Creation Process

```
1. Customer makes purchase
   ↓
2. INSERT into sales table
   ↓
3. Trigger updates customer.total_spent
   ↓
4. INSERT into sales_details table
   ↓
5. Trigger creates inventory transaction
   ↓
6. UPDATE products.stock (via stored procedure)
```

---

## Normalization

This database follows **Third Normal Form (3NF)**:

✅ **1NF**: All columns contain atomic values
✅ **2NF**: No partial dependencies
✅ **3NF**: No transitive dependencies

**Example of normalization**:
- Customer tier information is in separate table (customer_tiers)
- Product categories are in separate table (categories)
- No redundant data stored in multiple places

---

## Cardinality

| Relationship | Type | Description |
|--------------|------|-------------|
| Categories → Products | 1:M | One category has many products |
| Products → Sales Details | 1:M | One product in many sales |
| Customers → Sales | 1:M | One customer has many orders |
| Sales → Sales Details | 1:M | One sale has many line items |
| Customer Tiers → Customers | 1:M | One tier has many customers |
| Employees → Sales | 1:M | One employee processes many sales |
| Employees → Employees | 1:M | One manager has many reports |
| Payment Methods → Sales | 1:M | One method used in many sales |

---

## Sample Data Statistics

After loading sample data:

- **10 Products** across 5 categories
- **8 Customers** across 4 tier levels
- **5 Employees** in organizational hierarchy
- **10 Sales** transactions
- **10 Sales Detail** line items
- **5 Payment Methods**
- **4 Customer Tiers**

---

<div align="center">

**This schema supports complex business analytics and reporting!**

See `Advanced_SQL_Queries.sql` for 22+ example queries

</div>
