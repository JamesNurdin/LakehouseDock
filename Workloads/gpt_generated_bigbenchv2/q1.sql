WITH ws_agg AS (
    SELECT ws_customer_id,
           COUNT(*) AS transaction_cnt,
           SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_customer_id
)
SELECT c.c_customer_id,
       c.c_name,
       ws_agg.transaction_cnt,
       ws_agg.total_quantity
FROM ws_agg
JOIN customers c
  ON ws_agg.ws_customer_id = c.c_customer_id
ORDER BY ws_agg.total_quantity DESC
LIMIT 10
