WITH sales_joined AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        t.t_meal_time,
        t.t_hour
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
)
SELECT
    t_meal_time,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    'lunch' AS meal_category
FROM sales_joined
WHERE t_meal_time = 'lunch'
  AND t_hour BETWEEN 11 AND 13
GROUP BY t_meal_time

UNION ALL

SELECT
    t_meal_time,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    'dinner' AS meal_category
FROM sales_joined
WHERE t_meal_time = 'dinner'
  AND t_hour BETWEEN 18 AND 20
GROUP BY t_meal_time

ORDER BY total_sales DESC
LIMIT 100
