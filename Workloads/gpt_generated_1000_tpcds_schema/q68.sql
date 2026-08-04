WITH sales_agg AS (
    SELECT
        td.t_meal_time,
        td.t_am_pm,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_quantity >= 5
      AND ws.ws_wholesale_cost BETWEEN 60 AND 100
      AND ws.ws_ext_sales_price > 2000
      AND ws.ws_net_paid_inc_ship_tax < 15000
      AND td.t_shift = 'evening'
    GROUP BY td.t_meal_time, td.t_am_pm
)
SELECT
    t_meal_time,
    t_am_pm,
    total_sales,
    total_profit,
    order_cnt,
    CASE 
        WHEN total_profit > 5000 THEN 'High'
        WHEN total_profit BETWEEN 2000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (PARTITION BY t_meal_time ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank, t_meal_time
