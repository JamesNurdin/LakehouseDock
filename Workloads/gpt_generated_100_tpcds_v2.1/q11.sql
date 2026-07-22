WITH page_returns AS (
    SELECT
        cp.cp_catalog_page_number AS metric_key,
        'Catalog Page' AS metric_category,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_department = 'Women'
    GROUP BY cp.cp_catalog_page_number
),
month_returns AS (
    SELECT
        d.d_month_seq AS metric_key,
        'Month' AS metric_category,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 7
    GROUP BY d.d_month_seq
)
SELECT
    metric_category,
    metric_key,
    total_return_amount,
    SUM(total_return_amount) OVER (PARTITION BY metric_category ORDER BY metric_key) AS running_total
FROM (
    SELECT DISTINCT metric_category, metric_key, total_return_amount FROM page_returns
    UNION ALL
    SELECT DISTINCT metric_category, metric_key, total_return_amount FROM month_returns
) AS combined
ORDER BY metric_category, metric_key
LIMIT 100
