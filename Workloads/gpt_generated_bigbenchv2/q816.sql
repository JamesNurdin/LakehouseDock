WITH customer_sales AS (
    SELECT c.c_customer_id,
           c.c_name,
           COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
           SUM(ss.ss_quantity) AS total_quantity,
           AVG(ss.ss_quantity) AS avg_quantity_per_transaction
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT c_customer_id,
       c_name,
       transaction_count,
       total_quantity,
       avg_quantity_per_transaction
FROM customer_sales
ORDER BY total_quantity DESC
LIMIT 10
