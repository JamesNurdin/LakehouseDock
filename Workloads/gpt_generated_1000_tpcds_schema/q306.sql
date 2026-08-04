SELECT DISTINCT c.c_customer_id
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_date = DATE '2001-01-01'
  AND ws.ws_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2)
INTERSECT
SELECT DISTINCT c.c_customer_id
FROM store_sales ss
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_date = DATE '2001-01-01'
  AND ss.ss_net_profit > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
LIMIT 100
