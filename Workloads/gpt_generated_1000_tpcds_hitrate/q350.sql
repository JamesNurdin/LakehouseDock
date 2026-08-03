SELECT ws.ws_order_number,
       sm.sm_ship_mode_id,
       ws.ws_net_paid_inc_ship_tax
FROM   web_sales ws
JOIN   ship_mode sm
       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE  sm.sm_carrier = 'DHL'
  AND  ws.ws_net_paid_inc_ship_tax > 3000
LIMIT  10
