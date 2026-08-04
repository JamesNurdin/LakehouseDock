SELECT
    td.t_time_id,
    td.t_hour,
    ws.ws_order_number,
    ws.ws_net_profit
FROM web_sales ws
JOIN time_dim td
  ON ws.ws_sold_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND ws.ws_net_profit > 1000
LIMIT 100
