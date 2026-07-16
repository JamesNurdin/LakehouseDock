SELECT c.c_customer_id,
       sum(ws.ws_net_paid) AS total_spent
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY c.c_customer_id
ORDER BY total_spent DESC
LIMIT 10
