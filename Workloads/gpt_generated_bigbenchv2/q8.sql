WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    WHERE ss.ss_quantity > 0
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    c_customer_id,
    c_name,
    transaction_count,
    total_quantity
FROM customer_sales
ORDER BY total_quantity DESC
LIMIT 10
