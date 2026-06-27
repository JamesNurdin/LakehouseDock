WITH customer_store_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        ss.ss_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name, ss.ss_store_id
)
SELECT
    c_customer_id,
    c_name,
    ss_store_id,
    total_quantity,
    transaction_count,
    RANK() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS quantity_rank
FROM customer_store_sales
ORDER BY ss_store_id, quantity_rank
LIMIT 200
