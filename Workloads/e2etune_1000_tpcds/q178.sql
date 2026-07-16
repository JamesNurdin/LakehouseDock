WITH agg AS (
    SELECT
        i.i_category,
        sm.sm_type,
        t.t_shift,
        t.t_meal_time,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_shift = 'Evening'
      AND sm.sm_type = 'AIR'
      AND i.i_category = 'Electronics'
      AND t.t_hour BETWEEN 17 AND 23
      AND t.t_meal_time = 'Dinner'
      AND wp.wp_type = 'Content'
      AND wp.wp_max_ad_count > 5
    GROUP BY i.i_category, sm.sm_type, t.t_shift, t.t_meal_time
    HAVING SUM(ws.ws_quantity) > 100
)
SELECT
    agg.i_category,
    agg.sm_type,
    agg.t_shift,
    agg.t_meal_time,
    agg.total_net_profit,
    agg.total_quantity,
    agg.avg_discount,
    (agg.total_net_profit / NULLIF(agg.total_quantity, 0)) AS profit_per_unit,
    RANK() OVER (ORDER BY agg.total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 10
