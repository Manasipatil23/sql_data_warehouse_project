# Data Catalog: Gold Layer

The Gold layer is the business-ready layer of the warehouse. It is modelled as a **star schema** with two dimensions and one fact, all implemented as SQL Server views on top of the Silver layer.

---

## gold.dim_customers

**Purpose:** one row per customer, combining CRM customer data with ERP birthdate, gender and country.
**Rows:** 18,484

| Column | Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key generated in the warehouse (1, 2, 3, …). Used by `fact_sales`. |
| customer_id | INT | Customer ID from the CRM system. |
| customer_number | NVARCHAR(50) | Customer business key, e.g. `AW00011000`. Links CRM and ERP records. |
| first_name | NVARCHAR(50) | First name, trimmed. |
| last_name | NVARCHAR(50) | Last name, trimmed. |
| country | NVARCHAR(50) | Country of residence, e.g. `Germany`, `United States`; `n/a` if unknown. |
| marital_status | NVARCHAR(50) | `Married`, `Single` or `n/a`. |
| gender | NVARCHAR(50) | `Male`, `Female` or `n/a`. CRM is the master source; ERP fills in when CRM has no value. |
| birthdate | DATE | Date of birth from ERP. Future dates were set to NULL in Silver. |
| create_date | DATE | Date the customer record was created in the CRM. |

---

## gold.dim_products

**Purpose:** one row per current product (historical price periods removed), with its category.
**Rows:** 295

| Column | Type | Description |
|---|---|---|
| product_key | INT | Surrogate key generated in the warehouse. Used by `fact_sales`. |
| product_id | INT | Product ID from the CRM system. |
| product_number | NVARCHAR(50) | Product business key, e.g. `FR-R92B-58`. |
| product_name | NVARCHAR(50) | Descriptive product name. |
| category_id | NVARCHAR(50) | Category code, e.g. `CO_RF`. Links to the ERP category table. |
| category | NVARCHAR(50) | Top-level category: `Accessories`, `Bikes`, `Clothing`, `Components`. |
| subcategory | NVARCHAR(50) | More detailed classification, e.g. `Road Frames`. |
| maintenance | NVARCHAR(50) | Whether the product needs maintenance: `Yes` / `No`. |
| cost | INT | Base cost of the product. Missing costs were set to 0. |
| product_line | NVARCHAR(50) | `Mountain`, `Road`, `Touring`, `Other Sales` or `n/a`. |
| start_date | DATE | Date the current version of the product became available. |

---

## gold.fact_sales

**Purpose:** one row per sales order line, linked to the customer and product dimensions.
**Rows:** 60,398

| Column | Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Sales order ID, e.g. `SO43697`. |
| product_key | INT | Surrogate key linking to `gold.dim_products`. |
| customer_key | INT | Surrogate key linking to `gold.dim_customers`. |
| order_date | DATE | Date the order was placed. NULL where the source date was invalid. |
| shipping_date | DATE | Date the order was shipped. |
| due_date | DATE | Date payment was due. |
| sales_amount | INT | Total value of the line (= quantity × price, recalculated in Silver where wrong). |
| quantity | INT | Number of units ordered. |
| price | INT | Price per unit. |
