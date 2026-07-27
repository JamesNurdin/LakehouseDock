/* goal: Compare net paid sales by ship mode and meal time across catalog and web channels */
WITH cat_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_meal_time AS meal_time,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_ext_wholesale_cost > 500
    GROUP BY sm.sm_ship_mode_id, td.t_meal_time
),
web_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_meal_time AS meal_time,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_ext_wholesale_cost > 500
    GROUP BY sm.sm_ship_mode_id, td.t_meal_time
)
SELECT DISTINCT
    ship_mode_id,
    meal_time,
    channel,
    total_net_paid,
    order_cnt
FROM (
    SELECT ship_mode_id, meal_time, 'catalog' AS channel, total_net_paid, order_cnt FROM cat_agg
    UNION ALL
    SELECT ship_mode_id, meal_time, 'web' AS channel, total_net_paid, order_cnt FROM web_agg
) combined
ORDER BY ship_mode_id, meal_time, channel
LIMIT 100
