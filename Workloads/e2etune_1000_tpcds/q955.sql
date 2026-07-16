SELECT
    carrier,
    ship_type,
    order_cnt,
    total_net_profit,
    avg_discount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        sm.sm_carrier AS carrier,
        sm.sm_type AS ship_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND ws.ws_net_paid > 1000
    GROUP BY sm.sm_carrier, sm.sm_type
    HAVING SUM(ws.ws_net_profit) > 5000
) t
ORDER BY total_net_profit DESC
LIMIT 10
