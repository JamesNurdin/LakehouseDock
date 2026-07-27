WITH sales_cte AS (
    SELECT
        d.d_year AS year,
        'sales' AS metric_type,
        SUM(cs.cs_ext_sales_price) AS total_amount,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cs.cs_list_price > 100
    GROUP BY d.d_year
),
returns_cte AS (
    SELECT
        d.d_year AS year,
        'returns' AS metric_type,
        SUM(cr.cr_return_amount) AS total_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 50000 THEN 'High' ELSE 'Low' END AS amount_category
    FROM tpcds.catalog_returns cr
    JOIN tpcds.date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cr.cr_return_amount > 50
    GROUP BY d.d_year
)
SELECT *
FROM sales_cte
UNION ALL
SELECT *
FROM returns_cte
ORDER BY year, metric_type
