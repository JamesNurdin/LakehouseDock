SELECT d.d_year,
       SUM(ws.ws_net_paid) AS total_net_paid,
       COUNT(*) AS txn_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year
ORDER BY total_net_paid DESC
LIMIT 10
