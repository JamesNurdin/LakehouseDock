SELECT
  ws.ws_order_number,
  ws.ws_net_paid,
  ca.ca_city,
  ca.ca_state
FROM web_sales ws
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_gmt_offset = -5.00
  AND ws.ws_coupon_amt > 500
ORDER BY ws.ws_net_paid DESC
