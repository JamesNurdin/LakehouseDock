WITH sales_by_year AS (
    SELECT
        d.d_year,
        'sales_high_risk_male' AS metric,
        SUM(ss.ss_net_paid_inc_tax) AS metric_value
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_credit_rating = 'High Risk'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
),
catalog_pages_by_year AS (
    SELECT
        d.d_year,
        'catalog_careful_pages' AS metric,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS metric_value
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE cp.cp_description LIKE '%Careful%'
      AND d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year
)
SELECT *
FROM sales_by_year
UNION ALL
SELECT *
FROM catalog_pages_by_year
ORDER BY d_year, metric
LIMIT 100
