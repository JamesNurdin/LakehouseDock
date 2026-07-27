SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE c.c_birth_day = 27
  AND ws.ws_promo_sk = 1121
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY total_net_paid DESC
LIMIT 100
