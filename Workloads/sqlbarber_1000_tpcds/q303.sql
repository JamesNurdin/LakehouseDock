SELECT
  ws.ws_sold_date_sk,
  ws.ws_order_number,
  ws.ws_quantity,
  ws.ws_list_price,
  ws.ws_quantity * ws.ws_list_price AS total_list_price,
  ws.ws_ext_sales_price - ws.ws_ext_discount_amt AS net_sales,
  CASE
    WHEN ws.ws_quantity > 41 THEN ws.ws_quantity * ws.ws_list_price * 0.9
    ELSE ws.ws_quantity * ws.ws_list_price
  END AS discounted_price,
  CASE
    WHEN sm.sm_type = 'OVERNIGHT                     ' THEN 'Preferred'
    ELSE 'Standard'
  END AS ship_mode_category,
  ws.ws_ext_sales_price / NULLIF(ws.ws_quantity, 0) AS avg_price_per_item,
  ws.ws_net_profit + -1883.25 AS adjusted_profit
FROM web_sales ws
JOIN ship_mode sm
  ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451153 AND 2451142
  AND sm.sm_carrier = 'GREAT EASTERN       '
