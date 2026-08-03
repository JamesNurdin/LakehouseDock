WITH high_profit_orders AS (
  SELECT ws_order_number
  FROM web_sales
  WHERE ws_net_profit > 1000
)
SELECT
  CONCAT('Meal ', td.t_meal_time) AS meal_desc,
  td.t_hour,
  COUNT(DISTINCT sr.sr_ticket_number) AS returns_cnt,
  SUM(sr.sr_net_loss) AS returns_loss,
  COUNT(DISTINCT ws.ws_order_number) AS sales_cnt,
  SUM(ws.ws_net_profit) AS sales_profit
FROM store_returns sr
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN web_sales ws
  ON ws.ws_sold_time_sk = td.t_time_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE
  regexp_like(td.t_time_id, '^AAAA.*A$')
  AND w.w_suite_number LIKE '%Suite %'
  AND ws.ws_order_number IN (SELECT ws_order_number FROM high_profit_orders)
GROUP BY
  CONCAT('Meal ', td.t_meal_time),
  td.t_hour
ORDER BY
  sales_profit DESC,
  td.t_hour
LIMIT 100
