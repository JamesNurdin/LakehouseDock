WITH store_agg AS (
    SELECT
        'store_return' AS source,
        td.t_hour,
        td.t_meal_time,
        SUM(sr.sr_net_loss) AS total_amount
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_net_loss > 0
      AND td.t_meal_time = 'lunch'
    GROUP BY td.t_hour, td.t_meal_time
),
web_agg AS (
    SELECT
        'web_sale' AS source,
        td.t_hour,
        td.t_meal_time,
        SUM(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
      AND ws.ws_net_profit > 0
      AND td.t_meal_time = 'lunch'
    GROUP BY td.t_hour, td.t_meal_time
)
SELECT source, t_hour, t_meal_time, total_amount
FROM store_agg
UNION ALL
SELECT source, t_hour, t_meal_time, total_amount
FROM web_agg
ORDER BY source, t_hour, total_amount DESC
LIMIT 100
