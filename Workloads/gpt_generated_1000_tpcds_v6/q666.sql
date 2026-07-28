WITH avg_return AS (
    SELECT AVG(cr.cr_return_amount) AS overall_avg
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
),
returns_2020 AS (
    SELECT
        i.i_class AS class,
        SUM(cr.cr_return_amount) AS total_amount,
        'Return' AS metric_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
      AND r.r_reason_desc = 'Damaged'
      AND w.w_country = 'United States'
      AND cr.cr_return_amount > (SELECT overall_avg FROM avg_return)
    GROUP BY i.i_class
),
sales_2020 AS (
    SELECT
        i.i_class AS class,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        'Sales' AS metric_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2020
    GROUP BY i.i_class
)
SELECT class,
       total_amount,
       metric_type
FROM returns_2020
UNION ALL
SELECT class,
       total_amount,
       metric_type
FROM sales_2020
ORDER BY class ASC, metric_type DESC
LIMIT 100
