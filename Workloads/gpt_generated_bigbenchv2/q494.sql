WITH combined_sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales ws
)
SELECT c.c_customer_id,
       c.c_name,
       SUM(cs.quantity) AS total_quantity,
       COUNT(cs.quantity) AS total_transactions,
       SUM(CASE WHEN cs.channel = 'store' THEN cs.quantity ELSE 0 END) AS store_quantity,
       SUM(CASE WHEN cs.channel = 'store' THEN 1 ELSE 0 END) AS store_transactions,
       SUM(CASE WHEN cs.channel = 'web' THEN cs.quantity ELSE 0 END) AS web_quantity,
       SUM(CASE WHEN cs.channel = 'web' THEN 1 ELSE 0 END) AS web_transactions
FROM customers c
LEFT JOIN combined_sales cs
       ON cs.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name
ORDER BY total_quantity DESC
LIMIT 100
