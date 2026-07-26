WITH daily_profit AS (
 SELECT d.d_date,
        sm.sm_type,
        sm.sm_carrier,
        t.t_hour,
        SUM(cs.cs_net_profit) AS daily_net_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 GROUP BY d.d_date, sm.sm_type, sm.sm_carrier, t.t_hour
)
SELECT d_date,
       sm_type,
       sm_carrier,
       t_hour,
       daily_net_profit,
       CASE WHEN t_hour BETWEEN 6 AND 11 THEN 'Morning'
            WHEN t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN t_hour BETWEEN 18 AND 21 THEN 'Evening'
            ELSE 'Night' END AS time_of_day,
       CASE WHEN daily_net_profit > 10000 THEN 'High'
            WHEN daily_net_profit > 5000 THEN 'Medium'
            ELSE 'Low' END AS profit_category,
       RANK() OVER (PARTITION BY d_date ORDER BY daily_net_profit DESC) AS profit_rank
FROM daily_profit
ORDER BY d_date, profit_rank
