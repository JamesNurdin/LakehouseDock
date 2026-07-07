WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        AVG(ss.ss_quantity) AS avg_quantity,
        MAX(ss.ss_ts) AS last_purchase_ts
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    c_customer_id,
    c_name,
    total_quantity,
    transaction_count,
    avg_quantity,
    last_purchase_ts
FROM customer_sales
ORDER BY total_quantity DESC
LIMIT 10
