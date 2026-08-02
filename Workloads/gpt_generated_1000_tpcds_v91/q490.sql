WITH sales_summary AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'sales' AS source,
        SUM(cs.cs_net_profit) AS total_amount
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1998
    GROUP BY w.w_warehouse_name
),
returns_summary AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'returns' AS source,
        SUM(cr.cr_net_loss) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1998
    GROUP BY w.w_warehouse_name
),
unioned AS (
    SELECT warehouse_name, source, total_amount FROM sales_summary
    UNION ALL
    SELECT warehouse_name, source, total_amount FROM returns_summary
)
SELECT
    y.d_year AS year,
    u.warehouse_name,
    u.source,
    u.total_amount,
    (SELECT AVG(total_amount) FROM unioned) AS avg_total_amount
FROM unioned u
CROSS JOIN (
    SELECT d_year FROM date_dim WHERE d_year = 1998 GROUP BY d_year
) y
ORDER BY year, source, total_amount DESC
LIMIT 100
