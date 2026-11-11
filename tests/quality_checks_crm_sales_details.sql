USE DataWarehouse;
GO

-- ============================================================
-- Data quality checks: bronze.crm_sales_details
-- ============================================================

-- Check 1: extra spaces in order numbers
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.crm_sales_details
WHERE DATALENGTH(sls_ord_num) != DATALENGTH(TRIM(sls_ord_num));

-- Check 2: sales whose product key does not exist in the product table
-- Expectation: 0  |  Found: 0 (sales can be joined to products)
SELECT COUNT(*) AS rows_found
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT SUBSTRING(prd_key, 7, LEN(prd_key)) FROM bronze.crm_prd_info);

-- Check 3: sales whose customer ID does not exist in the customer table
-- Expectation: 0  |  Found: 0 (sales can be joined to customers)
SELECT COUNT(*) AS rows_found
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Check 4: invalid order dates (stored as numbers like 20101229)
-- Expectation: 0, 0  |  Found: 17 zero, 2 with the wrong length (e.g. 5489, 32154)
SELECT SUM(CASE WHEN sls_order_dt = 0 THEN 1 ELSE 0 END) AS zero_dates,
       SUM(CASE WHEN sls_order_dt != 0 AND LEN(sls_order_dt) != 8 THEN 1 ELSE 0 END) AS wrong_length
FROM bronze.crm_sales_details;

-- Check 5: invalid ship and due dates
-- Expectation: 0, 0  |  Found: 0, 0
SELECT SUM(CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN 1 ELSE 0 END) AS bad_ship_dates,
       SUM(CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN 1 ELSE 0 END) AS bad_due_dates
FROM bronze.crm_sales_details;

-- Check 6: order date after ship date or due date
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check 7: business rule  sales = quantity * price, and no NULL, zero or negative values
-- Expectation: 0  |  Found: 35
SELECT sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- Check 7b: breakdown of the problems in check 7
-- Found: 8 NULL sales, 5 sales <= 0, 7 NULL prices, 5 negative prices, quantity always OK
SELECT SUM(CASE WHEN sls_sales IS NULL THEN 1 ELSE 0 END) AS sales_null,
       SUM(CASE WHEN sls_sales <= 0 THEN 1 ELSE 0 END) AS sales_zero_or_negative,
       SUM(CASE WHEN sls_price IS NULL THEN 1 ELSE 0 END) AS price_null,
       SUM(CASE WHEN sls_price < 0 THEN 1 ELSE 0 END) AS price_negative,
       SUM(CASE WHEN sls_quantity IS NULL OR sls_quantity <= 0 THEN 1 ELSE 0 END) AS quantity_bad
FROM bronze.crm_sales_details;


-- ============================================================
-- After loading: verify silver.crm_sales_details
-- ============================================================

-- Expectation: 0 rows break the sales rule
SELECT COUNT(*) AS rows_found
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- Expectation: invalid order dates are now NULL (19), all other dates are real DATEs
SELECT SUM(CASE WHEN sls_order_dt IS NULL THEN 1 ELSE 0 END) AS null_order_dates,
       MIN(sls_order_dt) AS earliest_order,
       MAX(sls_order_dt) AS latest_order
FROM silver.crm_sales_details;
