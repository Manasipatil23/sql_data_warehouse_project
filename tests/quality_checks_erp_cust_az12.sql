USE DataWarehouse;
GO

-- ============================================================
-- Data quality checks: bronze.erp_cust_az12
-- ============================================================

-- Check 1: customer ID formats
-- Found: 11042 IDs start with an extra 'NAS' prefix (NASAW00011000), 7441 do not (AW00011000)
SELECT LEFT(cid, 3) AS prefix, COUNT(*) AS rows_found
FROM bronze.erp_cust_az12
GROUP BY LEFT(cid, 3);

-- Check 2: after removing 'NAS', does every ID match a CRM customer key?
-- Expectation: 0  |  Found: 0 (the ERP customers can be joined to the CRM customers)
SELECT COUNT(*) AS rows_found
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END
      NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Check 3: birthdates out of range
-- Found: 16 birthdates in the future (up to 9999-11-20), 15 customers older than 100
SELECT MIN(bdate) AS earliest,
       MAX(bdate) AS latest,
       SUM(CASE WHEN bdate > GETDATE() THEN 1 ELSE 0 END) AS future_birthdates,
       SUM(CASE WHEN bdate < '1924-01-01' THEN 1 ELSE 0 END) AS older_than_100
FROM bronze.erp_cust_az12;

-- Check 4: gender values (brackets make spaces visible)
-- Found: 'Male', 'Female', 'M ', 'F ', blank '  ' and NULL
SELECT '[' + gen + ']' AS gen_with_brackets, COUNT(*) AS rows_found
FROM bronze.erp_cust_az12
GROUP BY gen;


-- ============================================================
-- After loading: verify silver.erp_cust_az12
-- ============================================================

-- Expectation: no 'NAS' prefixes, no future birthdates
SELECT SUM(CASE WHEN cid LIKE 'NAS%' THEN 1 ELSE 0 END) AS nas_prefix_left,
       SUM(CASE WHEN bdate > GETDATE() THEN 1 ELSE 0 END) AS future_birthdates
FROM silver.erp_cust_az12;

-- Expectation: only Female, Male, n/a
SELECT gen, COUNT(*) AS rows_found
FROM silver.erp_cust_az12
GROUP BY gen;
