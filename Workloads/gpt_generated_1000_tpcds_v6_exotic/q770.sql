WITH cp_date AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_id,
        d.d_year,
        d.d_fy_quarter_seq,
        d.d_current_month
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_fy_quarter_seq IN (6, 9, 12)
      AND d.d_current_month = 'Y'
      AND cp.cp_catalog_number IN (1, 8, 19)
      AND cp.cp_catalog_page_number BETWEEN 5 AND 15
      AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
),
cust_with_year AS (
    SELECT
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        c.c_birth_year,
        c.c_birth_month,
        c.c_current_cdemo_sk,
        c.c_current_hdemo_sk,
        d.d_year AS cust_year
    FROM customer c
    JOIN date_dim d
        ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND c.c_current_hdemo_sk = 2064
      AND c.c_current_cdemo_sk = 1161742
      AND c.c_birth_month = 5
)
SELECT
    cpd.cp_department,
    cpd.d_year,
    COUNT(DISTINCT cust.c_customer_sk) AS distinct_customers,
    MIN(cust.c_birth_year) AS youngest_birth_year,
    MAX(cust.c_birth_year) AS oldest_birth_year,
    AVG(cust.c_birth_year) AS avg_birth_year
FROM cp_date cpd
JOIN cust_with_year cust
    ON cust.cust_year = cpd.d_year
GROUP BY cpd.cp_department, cpd.d_year
ORDER BY distinct_customers DESC, cpd.cp_department
LIMIT 100
