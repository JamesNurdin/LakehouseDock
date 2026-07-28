WITH ship_modes AS (
    SELECT sm_ship_mode_sk,
           sm_ship_mode_id,
           sm_type
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'RAIL')
)
SELECT
    'catalog' AS sales_channel,
    sm.sm_ship_mode_id,
    sm.sm_type,
    SUM(cs.cs_net_paid)        AS total_net_paid,
    SUM(cs.cs_net_profit)      AS total_net_profit
FROM catalog_sales cs
JOIN ship_modes sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_ext_list_price > 2000
GROUP BY sm.sm_ship_mode_id, sm.sm_type

UNION ALL

SELECT
    'web' AS sales_channel,
    sm.sm_ship_mode_id,
    sm.sm_type,
    SUM(ws.ws_net_paid)        AS total_net_paid,
    SUM(ws.ws_net_profit)      AS total_net_profit
FROM web_sales ws
JOIN ship_modes sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_net_paid_inc_ship_tax > 2000
GROUP BY sm.sm_ship_mode_id, sm.sm_type

LIMIT 100
