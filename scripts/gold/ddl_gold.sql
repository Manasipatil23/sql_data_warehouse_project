/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    Creates the Gold layer as a star schema:
    - gold.dim_customers  (dimension: who bought)
    - gold.dim_products   (dimension: what was bought)
    - gold.fact_sales     (fact: each sale, linked to both dimensions)

    The Gold objects are views: they store no data and always show the
    current Silver data, so no load procedure is needed.

Usage:
    SELECT * FROM gold.fact_sales;
===============================================================================
*/
USE DataWarehouse;
GO

-- =============================================================================
-- Dimension: gold.dim_customers
-- One row per customer, combining CRM customer data with ERP birthdate,
-- ERP gender (as a fallback) and ERP country.
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,   -- surrogate key
    ci.cst_id                              AS customer_id,
    ci.cst_key                             AS customer_number,
    ci.cst_firstname                       AS first_name,
    ci.cst_lastname                        AS last_name,
    la.cntry                               AS country,
    ci.cst_marital_status                  AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr             -- CRM is the master source for gender
        ELSE COALESCE(ca.gen, 'n/a')                           -- fall back to ERP when CRM has no value
    END                                    AS gender,
    ca.bdate                               AS birthdate,
    ci.cst_create_date                     AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Dimension: gold.dim_products
-- One row per current product (price history removed), with its category.
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,   -- surrogate key
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;   -- keep only the current version of each product
GO

-- =============================================================================
-- Fact: gold.fact_sales
-- One row per sales order line. Source IDs are replaced by the dimensions'
-- surrogate keys, so the fact table links directly to the star schema.
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
