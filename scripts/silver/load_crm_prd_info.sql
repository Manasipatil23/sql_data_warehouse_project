USE DataWarehouse;
GO

TRUNCATE TABLE silver.crm_prd_info;

INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,   -- category part, matches erp_px_cat_g1v2.id
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,          -- product part, matches crm_sales_details.sls_prd_key
    prd_nm,
    ISNULL(prd_cost, 0) AS prd_cost,                         -- missing cost -> 0
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,                                         -- codes -> readable names
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(
        DATEADD(day, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt))
        AS DATE
    ) AS prd_end_dt                                          -- end = day before the next start date
FROM bronze.crm_prd_info;

SELECT COUNT(*) FROM silver.crm_prd_info;
