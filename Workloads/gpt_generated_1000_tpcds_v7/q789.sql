WITH ws_city_stats AS (
    SELECT
        w.w_city,
        w.w_state,
        COUNT(ws.ws_order_number)                AS orders_cnt,
        SUM(ws.ws_net_profit)                    AS total_profit,
        AVG(ws.ws_net_paid_inc_ship_tax)         AS avg_paid_inc_tax
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ship_cdemo_sk IN (818597, 1754952, 359219)
      AND ws.ws_bill_cdemo_sk = 1815460
      AND ws.ws_net_paid_inc_ship_tax BETWEEN 500 AND 2000
      AND w.w_suite_number = 'Suite 350'
      AND w.w_city LIKE 'A%'
    GROUP BY w.w_city, w.w_state
)
SELECT
    w_city,
    w_state,
    orders_cnt,
    total_profit,
    avg_paid_inc_tax,
    total_profit / NULLIF(orders_cnt, 0) AS profit_per_order
FROM ws_city_stats
WHERE total_profit > 1000
ORDER BY profit_per_order DESC
LIMIT 10
