WITH suite_warehouses AS (
    SELECT w_warehouse_sk,
           w_warehouse_id,
           w_city,
           w_suite_number
    FROM warehouse
    WHERE w_suite_number LIKE 'Suite %'
),
period1 AS (
    SELECT w.w_warehouse_id,
           w.w_city,
           SUM(ws.ws_net_profit) AS profit_period1,
           COUNT(*) AS orders_period1
    FROM web_sales ws
    JOIN suite_warehouses w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY w.w_warehouse_id, w.w_city
),
period2 AS (
    SELECT w.w_warehouse_id,
           w.w_city,
           SUM(ws.ws_net_profit) AS profit_period2,
           COUNT(*) AS orders_period2
    FROM web_sales ws
    JOIN suite_warehouses w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451911 AND 2452275
    GROUP BY w.w_warehouse_id, w.w_city
)
SELECT combined.w_warehouse_id,
       combined.w_city,
       combined.total_profit,
       combined.total_orders,
       combined.period_label
FROM (
    SELECT p1.w_warehouse_id,
           p1.w_city,
           p1.profit_period1 AS total_profit,
           p1.orders_period1 AS total_orders,
           'Period1' AS period_label
    FROM period1 p1
    WHERE EXISTS (
        SELECT 1
        FROM warehouse w2
        WHERE w2.w_warehouse_id = p1.w_warehouse_id
          AND w2.w_suite_number = 'Suite 430 '
    )
    UNION ALL
    SELECT p2.w_warehouse_id,
           p2.w_city,
           p2.profit_period2 AS total_profit,
           p2.orders_period2 AS total_orders,
           'Period2' AS period_label
    FROM period2 p2
    WHERE p2.w_warehouse_id IN (
        SELECT w3.w_warehouse_id
        FROM warehouse w3
        WHERE w3.w_suite_number LIKE 'Suite %'
    )
) combined
ORDER BY combined.total_profit DESC
LIMIT 100
