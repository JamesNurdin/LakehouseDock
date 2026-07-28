SELECT DISTINCT ca.ca_city,
       ca.ca_state,
       ws.ws_net_profit
FROM web_sales ws
JOIN customer_address ca
  ON ws.ws_ship_addr_sk = ca.ca_address_sk
WHERE ws.ws_ship_date_sk = 2452333
  AND ws.ws_wholesale_cost > 20
ORDER BY ws.ws_net_profit DESC
LIMIT 100
