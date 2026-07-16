SELECT d.d_year,
       COUNT(*) AS order_count,
       SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2000
GROUP BY d.d_year
ORDER BY d.d_year
