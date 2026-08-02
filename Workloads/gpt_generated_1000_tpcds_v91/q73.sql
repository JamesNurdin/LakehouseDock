WITH sub_sales AS (
   SELECT
     t.t_hour,
     t.t_meal_time,
     ws.ws_ship_mode_sk,
     ws.ws_net_paid_inc_tax AS net_paid_inc_tax
   FROM web_sales ws
   CROSS JOIN LATERAL (
     SELECT t_hour, t_meal_time
     FROM time_dim
     WHERE t_time_sk = ws.ws_sold_time_sk
   ) t
   WHERE t.t_hour BETWEEN 6 AND 11
     AND ws.ws_net_paid_inc_tax > 500

   UNION ALL

   SELECT
     t.t_hour,
     t.t_meal_time,
     ws.ws_ship_mode_sk,
     ws.ws_net_paid_inc_tax AS net_paid_inc_tax
   FROM web_sales ws
   CROSS JOIN LATERAL (
     SELECT t_hour, t_meal_time
     FROM time_dim
     WHERE t_time_sk = ws.ws_sold_time_sk
   ) t
   WHERE t.t_hour BETWEEN 18 AND 22
     AND ws.ws_net_paid_inc_tax > 1000
)
SELECT
  t_hour,
  t_meal_time,
  ws_ship_mode_sk,
  SUM(net_paid_inc_tax) AS total_net_paid_inc_tax
FROM sub_sales
GROUP BY CUBE (t_hour, t_meal_time, ws_ship_mode_sk)
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
