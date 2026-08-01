SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'BAHAMAS'
  AND ws.ws_ext_sales_price > 1000
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_birth_country
ORDER BY total_sales DESC
LIMIT 100
