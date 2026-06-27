WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        SUM(s.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.ss_item_id) AS distinct_items,
        COUNT(DISTINCT s.ss_transaction_id) AS transaction_count,
        AVG(s.ss_quantity) AS avg_quantity_per_transaction,
        MIN(s.ss_ts) AS first_transaction_ts,
        MAX(s.ss_ts) AS last_transaction_ts
    FROM store_sales s
    JOIN customers c
        ON s.ss_customer_id = c.c_customer_id
    WHERE s.ss_store_id = 1
    GROUP BY c.c_customer_id, c.c_name
)
SELECT
    cs.c_customer_id,
    cs.c_name,
    cs.total_quantity,
    cs.distinct_items,
    cs.transaction_count,
    cs.avg_quantity_per_transaction,
    cs.first_transaction_ts,
    cs.last_transaction_ts,
    RANK() OVER (ORDER BY cs.total_quantity DESC) AS quantity_rank
FROM customer_sales cs
ORDER BY cs.total_quantity DESC
LIMIT 10
