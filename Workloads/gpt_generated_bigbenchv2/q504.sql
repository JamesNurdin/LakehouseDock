WITH sales_per_customer_store AS (
    SELECT
        ss_store_id,
        ss_customer_id,
        sum(ss_quantity) AS total_quantity,
        count(DISTINCT ss_transaction_id) AS transaction_count
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_store_id, ss_customer_id
)
SELECT
    sps.ss_store_id,
    c.c_customer_id,
    c.c_name,
    sps.total_quantity,
    sps.transaction_count,
    rank() OVER (PARTITION BY sps.ss_store_id ORDER BY sps.total_quantity DESC) AS store_customer_rank
FROM sales_per_customer_store sps
JOIN customers c
    ON sps.ss_customer_id = c.c_customer_id
ORDER BY sps.ss_store_id, store_customer_rank
LIMIT 20
