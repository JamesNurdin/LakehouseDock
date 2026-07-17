SELECT SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
WHERE t.t_hour = 14
  AND ws.ws_sales_price > 100
