SELECT DISTINCT ca.ca_state, ca.ca_city, ws.ws_net_paid_inc_tax
FROM web_sales ws
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'TX'
  AND ws.ws_ext_wholesale_cost > 2000.00
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
