WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ws.ws_wholesale_cost > 20
    GROUP BY d.d_year, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND wr.wr_return_amt > 10
    GROUP BY d.d_year, w.w_warehouse_name
)
SELECT DISTINCT
    t.year,
    t.warehouse,
    t.metric_value,
    t.metric_type,
    CASE WHEN t.metric_value > 50000 THEN 'HIGH' ELSE 'LOW' END AS value_category
FROM (
    SELECT
        year,
        warehouse,
        total_sales AS metric_value,
        'sales' AS metric_type
    FROM sales_agg
    UNION ALL
    SELECT
        year,
        warehouse,
        total_returns AS metric_value,
        'returns' AS metric_type
    FROM returns_agg
) t
ORDER BY t.year, t.warehouse, t.metric_type
LIMIT 100
