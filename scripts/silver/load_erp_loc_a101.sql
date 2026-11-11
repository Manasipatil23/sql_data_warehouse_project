USE DataWarehouse;
GO

TRUNCATE TABLE silver.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (
    cid,
    cntry
)
SELECT
    REPLACE(cid, '-', '') AS cid,                            -- AW-00011000 -> AW00011000
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry                                             -- one spelling per country, blanks -> n/a
FROM bronze.erp_loc_a101;

SELECT COUNT(*) FROM silver.erp_loc_a101;
