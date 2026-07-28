SELECT ws.ws_order_number,
       ws.ws_net_paid_inc_ship_tax,
       td.t_hour,
       td.t_minute
FROM   web_sales ws
JOIN   time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
WHERE  td.t_shift = 'second'
  AND  ws.ws_net_paid_inc_ship_tax > 1500
ORDER BY ws.ws_net_paid_inc_ship_tax DESC
LIMIT 10
