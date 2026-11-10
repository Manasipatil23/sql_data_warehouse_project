USE DataWarehouse;

SELECT cst_id , COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;


SELECT * FROM bronze.crm_cust_info
WHERE cst_id = 29466;


SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
WHERE cst_id = 29466;


SELECT *
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;



SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- ============================================================
-- Data quality checks: bronze.crm_cust_info
-- ============================================================

-- Check: extra spaces in first names (DATALENGTH also catches trailing spaces)
-- Expectation: 0 rows  |  Found: 17
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_firstname) != DATALENGTH(TRIM(cst_firstname));

-- Check 1: extra spaces in last names
-- Expectation: 0  |  Found: 22
SELECT COUNT(*) AS rows_found
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_lastname) != DATALENGTH(TRIM(cst_lastname));

-- Check 2: which gender values exist?
-- Found: M, F, NULL
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

-- Check 3: which marital status values exist?
-- Found: M, S, NULL
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

-- Check 4: extra spaces in the customer key
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_key) != DATALENGTH(TRIM(cst_key));

-- Check 5: extra spaces in the gender and marital codes
-- Expectation: 0  |  Found: 0
SELECT COUNT(*) AS rows_found
FROM bronze.crm_cust_info
WHERE DATALENGTH(cst_gndr) != DATALENGTH(TRIM(cst_gndr))
   OR DATALENGTH(cst_marital_status) != DATALENGTH(TRIM(cst_marital_status));

-- Check 6: rows per gender
-- Found: M = 7068, F = 6848, NULL = 4577
SELECT cst_gndr, COUNT(*) AS rows_found
FROM bronze.crm_cust_info
GROUP BY cst_gndr;

-- Check 7: rows per marital status
-- Found: M = 10013, S = 8474, NULL = 6
SELECT cst_marital_status, COUNT(*) AS rows_found
FROM bronze.crm_cust_info
GROUP BY cst_marital_status;

-- Check 8: date range and missing dates
-- Found: 2025-10-06 to 2026-01-27, 3 NULL dates (the rows with no cst_id)
SELECT MIN(cst_create_date) AS earliest,
       MAX(cst_create_date) AS latest,
       SUM(CASE WHEN cst_create_date IS NULL THEN 1 ELSE 0 END) AS null_dates
FROM bronze.crm_cust_info;
