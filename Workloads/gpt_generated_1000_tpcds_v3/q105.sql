WITH sales_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        t.t_hour AS hour_of_day,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY sm.sm_ship_mode_id, t.t_hour

    UNION ALL

    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_cnt,
        'web' AS source
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY sm.sm_ship_mode_id, t.t_hour
)
SELECT
    ship_mode_id,
    hour_of_day,
    source,
    total_net_profit,
    order_cnt
FROM sales_agg
ORDER BY ship_mode_id, hour_of_day, source
