USE DataWarehouse;
GO

TRUNCATE TABLE silver.erp_px_cat_g1v2;

-- The quality checks found no problems, so the data is copied as it is
INSERT INTO silver.erp_px_cat_g1v2 (
    id,
    cat,
    subcat,
    maintenance
)
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT COUNT(*) FROM silver.erp_px_cat_g1v2;
