WITH profit_by_shift AS (
    SELECT
        td.t_meal_time AS meal_time,
        td.t_sub_shift AS sub_shift,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_meal_time IN ('dinner', 'breakfast')
      AND ws.ws_web_site_sk IN (52, 15)
    GROUP BY td.t_meal_time, td.t_sub_shift
)
SELECT
    profit_by_shift.meal_time,
    AVG(profit_by_shift.total_net_profit) AS avg_profit_per_shift,
    SUM(profit_by_shift.order_count) AS total_orders
FROM profit_by_shift
GROUP BY profit_by_shift.meal_time
HAVING AVG(profit_by_shift.total_net_profit) > 5000
ORDER BY avg_profit_per_shift DESC
