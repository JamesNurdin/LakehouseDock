WITH sales_data AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_color AS item_color,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_amount,
        SUM(cs.cs_quantity) AS total_quantity,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2 WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1999
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_color IN ('red', 'yellow')
    GROUP BY w.w_warehouse_name, w.w_warehouse_sk, i.i_color
), returns_data AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        i.i_color AS item_color,
        'returns' AS metric_type,
        SUM(cr.cr_return_amount) AS total_amount,
        SUM(cr.cr_return_quantity) AS total_quantity,
        (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2 WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk) AS avg_warehouse_net_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 1999
      AND t2.t_hour BETWEEN 9 AND 17
      AND i.i_color IN ('red', 'yellow')
    GROUP BY w.w_warehouse_name, w.w_warehouse_sk, i.i_color
)
SELECT
    warehouse_name,
    item_color,
    metric_type,
    total_amount,
    total_quantity,
    avg_warehouse_net_profit
FROM sales_data
UNION ALL
SELECT
    warehouse_name,
    item_color,
    metric_type,
    total_amount,
    total_quantity,
    avg_warehouse_net_profit
FROM returns_data
ORDER BY warehouse_name, item_color, metric_type
LIMIT 100
