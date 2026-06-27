WITH customer_store_sales AS (
    SELECT
        customers.c_customer_id,
        customers.c_name,
        store_sales.ss_store_id,
        SUM(store_sales.ss_quantity) AS total_quantity,
        COUNT(DISTINCT store_sales.ss_transaction_id) AS transaction_count
    FROM store_sales
    JOIN customers
        ON store_sales.ss_customer_id = customers.c_customer_id
    WHERE store_sales.ss_quantity > 0
    GROUP BY customers.c_customer_id, customers.c_name, store_sales.ss_store_id
)
SELECT
    cs.c_customer_id,
    cs.c_name,
    cs.ss_store_id,
    cs.total_quantity,
    cs.transaction_count,
    RANK() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS rank_within_store
FROM customer_store_sales cs
ORDER BY cs.total_quantity DESC
LIMIT 50
