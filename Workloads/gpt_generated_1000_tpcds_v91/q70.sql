SELECT d.d_date,
       SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
       COUNT(*) AS order_count
FROM web_sales ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_quarter_seq = 5
  AND ws.ws_warehouse_sk = 4
GROUP BY d.d_date
ORDER BY d.d_date
