SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    sm.sm_carrier,
    sm.sm_type
FROM tpcds.web_sales ws
JOIN tpcds.ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND ws.ws_ext_discount_amt > 1000
LIMIT 100
