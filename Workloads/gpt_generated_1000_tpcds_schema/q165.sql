SELECT
  ca.ca_state,
  ca.ca_city,
  SUM(ws.ws_net_profit) AS total_profit,
  SUM(ws.ws_ext_sales_price) AS total_sales
FROM tpcds.web_sales ws
JOIN tpcds.customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ws.ws_list_price > 50
GROUP BY ca.ca_state, ca.ca_city
ORDER BY total_profit DESC
LIMIT 10
