SELECT c.c_customer_id,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS txn_count
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE ws.ws_sold_date_sk >= 2451545
GROUP BY c.c_customer_id
ORDER BY total_net_paid DESC
LIMIT 10
