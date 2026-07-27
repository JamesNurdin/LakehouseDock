WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        cp.cp_end_date_sk
    FROM catalog_page cp
    WHERE regexp_like(cp.cp_description, '(?i)economic|gentle')
      AND cp.cp_description LIKE '%field%'
)
SELECT
    fp.cp_department,
    fp.cp_type,
    concat(fp.cp_department, ' - ', fp.cp_type) AS dept_type,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MIN(d_end.d_date) AS earliest_end_date,
    MAX(d_end.d_date) AS latest_end_date,
    SUBSTRING(fp.cp_description, 1, 10) AS desc_prefix
FROM filtered_pages fp
JOIN date_dim d_end
    ON fp.cp_end_date_sk = d_end.d_date_sk
JOIN customer c
    ON c.c_first_sales_date_sk = d_end.d_date_sk
GROUP BY
    fp.cp_department,
    fp.cp_type,
    concat(fp.cp_department, ' - ', fp.cp_type),
    SUBSTRING(fp.cp_description, 1, 10)
ORDER BY distinct_customers DESC
LIMIT 100
