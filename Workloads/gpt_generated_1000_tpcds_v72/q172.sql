WITH bs AS (
   SELECT
      td.t_hour,
      td.t_meal_time,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(ws.ws_quantity) AS total_quantity,
      RANK() OVER (PARTITION BY td.t_meal_time ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'breakfast'
     AND ws.ws_coupon_amt > 500
   GROUP BY td.t_hour, td.t_meal_time
   HAVING SUM(ws.ws_net_profit) > 1000
),

dn AS (
   SELECT
      td.t_hour,
      td.t_meal_time,
      SUM(ws.ws_net_profit) AS total_net_profit,
      SUM(ws.ws_quantity) AS total_quantity,
      RANK() OVER (PARTITION BY td.t_meal_time ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
   FROM web_sales ws
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'dinner'
     AND ws.ws_coupon_amt < 2000
   GROUP BY td.t_hour, td.t_meal_time
   HAVING SUM(ws.ws_net_profit) > 1500
),

combined AS (
   SELECT * FROM bs
   UNION ALL
   SELECT * FROM dn
)
SELECT
   c.t_hour,
   c.t_meal_time,
   c.total_net_profit,
   c.total_quantity,
   c.profit_rank
FROM combined c
WHERE NOT EXISTS (
   SELECT 1
   FROM web_sales ws3
   JOIN time_dim td3 ON ws3.ws_sold_time_sk = td3.t_time_sk
   WHERE td3.t_hour = c.t_hour
     AND ws3.ws_coupon_amt > 5000
)
ORDER BY c.t_meal_time, c.total_net_profit DESC
LIMIT 100
