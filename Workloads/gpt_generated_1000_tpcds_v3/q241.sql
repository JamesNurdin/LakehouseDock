WITH sales_agg AS (
    SELECT
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year IN (2000, 2001)
    GROUP BY d.d_year, w.w_warehouse_name
),
returns_agg AS (
    SELECT
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_status
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year IN (2000, 2001)
    GROUP BY d.d_year, w.w_warehouse_name
)
SELECT
    d_year AS year,
    w_warehouse_name AS warehouse_name,
    'Sales' AS metric_type,
    total_net_profit AS metric_value,
    profit_status AS status
FROM sales_agg
UNION ALL
SELECT
    d_year AS year,
    w_warehouse_name AS warehouse_name,
    'Returns' AS metric_type,
    total_net_loss AS metric_value,
    loss_status AS status
FROM returns_agg
ORDER BY year, warehouse_name, metric_type
