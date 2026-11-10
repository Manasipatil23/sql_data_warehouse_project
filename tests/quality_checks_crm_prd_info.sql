USE DataWarehouse;
GO

-- ============================================================
-- Data quality checks: bronze.crm_prd_info
-- ============================================================

-- Check 1: NULL or duplicate product IDs
-- Expectation: no rows  |  Found: no rows
SELECT prd_id, COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check 2: extra spaces in product names
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.crm_prd_info
WHERE DATALENGTH(prd_nm) != DATALENGTH(TRIM(prd_nm));

-- Check 3: missing or negative costs
-- Expectation: 0 and 0  |  Found: 2 NULL, 0 negative
SELECT SUM(CASE WHEN prd_cost IS NULL THEN 1 ELSE 0 END) AS null_cost,
       SUM(CASE WHEN prd_cost < 0 THEN 1 ELSE 0 END) AS negative_cost
FROM bronze.crm_prd_info;

-- Check 4: product line values (brackets make trailing spaces visible)
-- Found: 'M ', 'R ', 'S ', 'T ' (each with a trailing space) and 17 NULL
SELECT '[' + prd_line + ']' AS prd_line_with_brackets, COUNT(*) AS rows_found
FROM bronze.crm_prd_info
GROUP BY prd_line;

-- Check 5: end date before start date
-- Expectation: 0  |  Found: 200
SELECT COUNT(*) AS rows_found
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- Check 5b: example of the date problem (one product, three price periods)
SELECT prd_id, prd_key, prd_cost, prd_start_dt, prd_end_dt
FROM bronze.crm_prd_info
WHERE prd_key = 'AC-HE-HL-U509-R'
ORDER BY prd_start_dt;

-- Check 6: category part of prd_key (first 5 chars, '-' -> '_') missing from erp_px_cat_g1v2
-- Found: 7 products with cat_id 'CO_PE' (no matching category)
SELECT prd_id, prd_key, REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN (SELECT id FROM bronze.erp_px_cat_g1v2);

-- Check 7: product part of prd_key (from char 7) that never appears in sales
-- Found: 220 product rows never sold (expected for old or unsold products)
SELECT COUNT(*) AS products_never_sold
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN (SELECT sls_prd_key FROM bronze.crm_sales_details);

-- Check 8: preview of the date fix with LEAD()
-- New end date = the day before the next start date of the same product
SELECT prd_id, prd_key, prd_start_dt, prd_end_dt,
       DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS new_end_dt
FROM bronze.crm_prd_info
WHERE prd_key = 'AC-HE-HL-U509-R';
