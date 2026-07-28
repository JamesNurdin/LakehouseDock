WITH sales_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_dom IN (10, 16, 3)
      AND cp.cp_catalog_page_number IN (5, 9, 14)
      AND cp.cp_end_date_sk > 2450000
    GROUP BY cp.cp_department, cp.cp_type, d.d_year
)
SELECT
    sa.cp_department,
    sa.cp_type,
    sa.d_year,
    sa.total_net_paid,
    sa.sales_cnt,
    RANK() OVER (PARTITION BY sa.cp_department ORDER BY sa.total_net_paid DESC) AS dept_rank,
    AVG(sa.total_net_paid) OVER (PARTITION BY sa.cp_type) AS avg_net_by_type
FROM sales_agg sa
JOIN date_dim d2
    ON d2.d_year = sa.d_year
JOIN web_page wp
    ON wp.wp_creation_date_sk = d2.d_date_sk
WHERE wp.wp_max_ad_count >= 2
  AND wp.wp_type = 'Content'
  AND wp.wp_web_page_id LIKE 'AAAAAAA%'
ORDER BY dept_rank, sa.cp_department
LIMIT 100
