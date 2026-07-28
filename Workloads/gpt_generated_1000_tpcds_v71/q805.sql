WITH combined_data AS (
    SELECT
        cp.cp_department AS department,
        cs.cs_ext_sales_price AS amount,
        cs.cs_quantity AS quantity,
        'Sales' AS metric_type
    FROM catalog_sales AS cs
    JOIN date_dim AS dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN catalog_page AS cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2001
      AND cp.cp_department = 'Books'
    UNION ALL
    SELECT
        cp.cp_department AS department,
        cr.cr_return_amount AS amount,
        cr.cr_return_quantity AS quantity,
        'Returns' AS metric_type
    FROM catalog_returns AS cr
    JOIN date_dim AS dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN catalog_page AS cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE dd.d_year = 2001
      AND cp.cp_department = 'Books'
)
SELECT
    department,
    metric_type,
    SUM(amount) AS total_amount,
    SUM(quantity) AS total_quantity,
    CASE WHEN SUM(amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category
FROM combined_data
GROUP BY department, metric_type
HAVING SUM(quantity) > 50
ORDER BY department, metric_type
