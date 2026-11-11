USE DataWarehouse;
GO

-- ============================================================
-- Data quality checks: bronze.erp_px_cat_g1v2
-- ============================================================

-- Check 1: NULL or duplicate category IDs
-- Expectation: no rows  |  Found: no rows
SELECT id, COUNT(*)
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1 OR id IS NULL;

-- Check 2: extra spaces in any text column
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.erp_px_cat_g1v2
WHERE DATALENGTH(cat) != DATALENGTH(TRIM(cat))
   OR DATALENGTH(subcat) != DATALENGTH(TRIM(subcat))
   OR DATALENGTH(maintenance) != DATALENGTH(TRIM(maintenance));

-- Check 3: category values
-- Found: Accessories, Bikes, Clothing, Components (clean)
SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

-- Check 4: maintenance values
-- Found: Yes (20), No (17) (clean)
SELECT maintenance, COUNT(*) AS rows_found
FROM bronze.erp_px_cat_g1v2
GROUP BY maintenance;

-- Result: this table is already clean, so Silver copies it as it is.
