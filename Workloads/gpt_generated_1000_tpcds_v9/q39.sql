WITH page_customer_stats AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        d.d_year,
        COUNT(DISTINCT c.c_customer_id) AS customer_cnt,
        SUM(cp.cp_catalog_number) AS total_catalog_number,
        CASE WHEN cp.cp_catalog_number > 12 THEN 'High' ELSE 'Low' END AS catalog_size_category
    FROM catalog_page cp
    JOIN date_dim d
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer c
        ON c.c_first_shipto_date_sk = d.d_date_sk
    WHERE cp.cp_catalog_number IN (10, 13, 15)
      AND cp.cp_type = 'C'
      AND cp.cp_description LIKE '%goods%'
      AND d.d_moy = 5
      AND d.d_current_month = 'Y'
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND c.c_email_address LIKE '%@%org%'
      AND c.c_birth_year BETWEEN 1960 AND 1970
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        d.d_year,
        CASE WHEN cp.cp_catalog_number > 12 THEN 'High' ELSE 'Low' END
)
SELECT
    cp_catalog_page_id,
    cp_department,
    cp_catalog_number,
    cp_catalog_page_number,
    d_year,
    customer_cnt,
    total_catalog_number,
    catalog_size_category,
    LAG(customer_cnt) OVER (PARTITION BY cp_department ORDER BY cp_catalog_page_id) AS prev_customer_cnt,
    SUM(customer_cnt) OVER (PARTITION BY cp_department ORDER BY cp_catalog_page_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_customer_cnt
FROM page_customer_stats
ORDER BY cp_department, cp_catalog_page_id
