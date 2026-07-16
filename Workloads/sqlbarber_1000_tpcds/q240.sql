SELECT c.c_customer_id,
       SUM(ws.ws_net_profit) AS total_net_profit
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_net_profit DESC
LIMIT 100
