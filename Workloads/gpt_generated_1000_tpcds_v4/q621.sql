WITH sales_agg AS (
    SELECT
        w.w_warehouse_name,
        t.t_shift,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        CASE
            WHEN SUM(ws.ws_quantity) > 1000 THEN 'High Volume'
            WHEN SUM(ws.ws_quantity) > 500 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_street_type IN ('Road', 'Avenue', 'Way')
      AND t.t_shift IN ('first', 'second')
      AND ws.ws_wholesale_cost > 70
    GROUP BY w.w_warehouse_name, t.t_shift
)
SELECT
    volume_category,
    AVG(total_profit) AS avg_profit,
    SUM(total_quantity) AS sum_quantity,
    COUNT(*) AS num_warehouse_shifts
FROM sales_agg
WHERE total_quantity > 0
GROUP BY volume_category
HAVING COUNT(*) >= 1
ORDER BY avg_profit DESC
LIMIT 100
