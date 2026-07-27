WITH filtered AS (
    SELECT
        sm.sm_carrier,
        sm.sm_code,
        regexp_extract(sm.sm_ship_mode_id, '(A+)', 1) AS ship_mode_pattern,
        td.t_meal_time,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE sm.sm_carrier LIKE 'F%'
      AND regexp_like(sm.sm_code, '^A')
      AND td.t_meal_time = 'dinner'
)
SELECT
    sm_carrier,
    t_meal_time,
    ship_mode_pattern,
    SUM(ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(ws_net_profit) > 5000 THEN 'high'
        WHEN SUM(ws_net_profit) > 1000 THEN 'medium'
        ELSE 'low'
    END AS profit_category,
    CONCAT(sm_carrier, '_', t_meal_time) AS carrier_meal_key
FROM filtered
GROUP BY sm_carrier, t_meal_time, ship_mode_pattern
ORDER BY total_profit DESC
LIMIT 100
