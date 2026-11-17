USE DataWarehouse;
GO

-- ============================================================
-- Before building Gold: explore the joins
-- ============================================================

-- Check 1: joining the 3 customer tables must not duplicate customers
-- Expectation: joined_rows = customers  |  Found: 18484 = 18484
SELECT COUNT(*) AS joined_rows, COUNT(DISTINCT ci.cst_id) AS customers
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid;

-- Check 2: CRM customers with no matching ERP row
-- Found: 1 customer has no ERP details (birthdate/gender), 0 have no location
SELECT SUM(CASE WHEN ca.cid IS NULL THEN 1 ELSE 0 END) AS no_erp_details,
       SUM(CASE WHEN la.cid IS NULL THEN 1 ELSE 0 END) AS no_location
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la ON ci.cst_key = la.cid;

-- Check 3: gender in CRM vs ERP
-- Found: 57 customers where the two systems disagree, and 4554 where CRM is n/a
--        but ERP knows the gender. Rule: CRM wins, ERP fills the gaps.
SELECT ci.cst_gndr AS crm_gender,
       ISNULL(ca.gen, '(no ERP row)') AS erp_gender,
       COUNT(*) AS rows_found
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca ON ci.cst_key = ca.cid
GROUP BY ci.cst_gndr, ca.gen
ORDER BY 1, 2;

-- Check 4: current products (no end date) must be unique per product key
-- Expectation: current_rows = distinct_keys  |  Found: 295 = 295
SELECT COUNT(*) AS current_rows, COUNT(DISTINCT prd_key) AS distinct_keys
FROM silver.crm_prd_info
WHERE prd_end_dt IS NULL;

-- Check 5: current products without a category
-- Found: 7 (the CO_PE products found in the crm_prd_info checks)
SELECT COUNT(*) AS no_category
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL AND pc.id IS NULL;


-- ============================================================
-- After building Gold: verify the star schema
-- ============================================================

-- Check 6: surrogate keys must be unique
-- Expectation: no rows
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check 7: referential integrity, every sale must find its customer and product
-- Expectation: no rows
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;

-- Check 8: no sales lost between Silver and Gold
-- Expectation: equal counts  |  Found: 60398 = 60398
SELECT (SELECT COUNT(*) FROM silver.crm_sales_details) AS silver_sales,
       (SELECT COUNT(*) FROM gold.fact_sales) AS gold_sales;


-- ============================================================
-- Example business question: total sales per country
-- ============================================================
SELECT c.country,
       SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sales DESC;
