WITH monthly_ship_mode AS (
    SELECT
        sm.sm_type,
        sm.sm_carrier,
        date_trunc('month', from_unixtime(ws.ws_sold_date_sk * 86400)) AS month,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS discount_rate
    FROM web_sales ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IN ('EXPRESS', 'NEXT DAY', 'OVERNIGHT')
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450999
    GROUP BY sm.sm_type, sm.sm_carrier, date_trunc('month', from_unixtime(ws.ws_sold_date_sk * 86400))
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT
    sm_type,
    sm_carrier,
    month,
    total_net_profit,
    total_quantity,
    avg_discount,
    discount_rate,
    RANK() OVER (PARTITION BY month ORDER BY total_net_profit DESC) AS profit_rank
FROM monthly_ship_mode
ORDER BY month DESC, profit_rank
LIMIT 20
