# Naming Conventions

## General
- `snake_case`: lowercase letters with underscores.
- English names only; no SQL reserved words.

## Tables and views

| Layer | Pattern | Example |
|---|---|---|
| Bronze | `<source>_<original_name>` | `bronze.crm_cust_info` |
| Silver | `<source>_<original_name>` | `silver.crm_cust_info` |
| Gold | `<category>_<entity>` | `gold.dim_customers`, `gold.fact_sales` |

Gold categories: `dim_` = dimension, `fact_` = fact.

## Columns
- **Surrogate keys:** `<entity>_key`, e.g. `customer_key`.
- **Technical columns:** `dwh_<name>`, e.g. `dwh_create_date` (load timestamp added by the warehouse).
- Bronze and Silver keep the source column names; Gold uses business-friendly names (`first_name`, `country`).

## Stored procedures
- `load_<layer>`, e.g. `bronze.load_bronze`, `silver.load_silver`.

## Files
- `scripts/<layer>/ddl_<layer>.sql`: table or view definitions.
- `scripts/silver/load_<table>.sql`: cleaning logic per table.
- `tests/quality_checks_<table>.sql`: data quality checks per table.
