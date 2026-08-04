WITH cp_agg AS (
    SELECT
        cp_end_date_sk,
        cp_department,
        COUNT(*) AS page_cnt,
        MIN(cp_catalog_number) AS min_catalog_num,
        MAX(cp_catalog_number) AS max_catalog_num
    FROM catalog_page
    WHERE cp_catalog_number BETWEEN 15 AND 25
      AND cp_department IN ('Books', 'Electronics', 'Clothing')
    GROUP BY cp_end_date_sk, cp_department
)
SELECT
    d.d_year,
    cp_agg.cp_department,
    cp_agg.page_cnt,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT cp_agg.cp_end_date_sk) AS distinct_end_dates,
    SUM(cp_agg.max_catalog_num) AS total_max_catalog_num,
    AVG(cp_agg.min_catalog_num) AS avg_min_catalog_num
FROM cp_agg
JOIN date_dim d
  ON cp_agg.cp_end_date_sk = d.d_date_sk
JOIN customer c
  ON c.c_first_sales_date_sk = d.d_date_sk
WHERE d.d_year = 1999
  AND d.d_quarter_seq = 15
  AND c.c_birth_month = 12
  AND d.d_year = (
        SELECT MAX(d2.d_year)
        FROM date_dim d2
        WHERE d2.d_quarter_seq = 15
    )
GROUP BY d.d_year, cp_agg.cp_department, cp_agg.page_cnt
ORDER BY total_max_catalog_num DESC
LIMIT 100
