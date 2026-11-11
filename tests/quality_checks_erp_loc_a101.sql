USE DataWarehouse;
GO

-- ============================================================
-- Data quality checks: bronze.erp_loc_a101
-- ============================================================

-- Check 1: customer ID format
-- Found: IDs contain a dash (AW-00011000), the CRM key does not (AW00011000)
SELECT TOP 5 cid
FROM bronze.erp_loc_a101;

-- Check 2: after removing the dash, does every ID match a CRM customer key?
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.erp_loc_a101
WHERE REPLACE(cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 3: country values (brackets make blanks visible)
-- Found: the same country written different ways (DE / Germany, US / USA / United States),
--        5 blank values and 332 NULL
SELECT '[' + cntry + ']' AS cntry_with_brackets, COUNT(*) AS rows_found
FROM bronze.erp_loc_a101
GROUP BY cntry
ORDER BY cntry;


-- ============================================================
-- After loading: verify silver.erp_loc_a101
-- ============================================================

-- Expectation: no dashes left in IDs
SELECT COUNT(*) AS ids_with_dash
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';

-- Expectation: one spelling per country, plus n/a
SELECT cntry, COUNT(*) AS rows_found
FROM silver.erp_loc_a101
GROUP BY cntry
ORDER BY cntry;
