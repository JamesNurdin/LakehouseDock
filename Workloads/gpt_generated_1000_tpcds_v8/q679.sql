SELECT ca.ca_state,
       COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
       SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ws.ws_list_price > 150.00
  AND ca.ca_city = 'Lincoln'
GROUP BY ca.ca_state
ORDER BY total_profit DESC
LIMIT 100
