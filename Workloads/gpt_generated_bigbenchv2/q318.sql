WITH store_customer_sales AS (
    SELECT
        ss_store_id,
        ss_customer_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_transaction_id) AS transaction_count,
        AVG(ss_quantity) AS avg_quantity_per_tx
    FROM store_sales
    GROUP BY ss_store_id, ss_customer_id
    HAVING SUM(ss_quantity) > 0
)
SELECT
    scs.ss_store_id,
    c.c_customer_id,
    c.c_name,
    scs.total_quantity,
    scs.transaction_count,
    scs.avg_quantity_per_tx,
    ROW_NUMBER() OVER (PARTITION BY scs.ss_store_id ORDER BY scs.total_quantity DESC) AS rank_in_store
FROM store_customer_sales scs
JOIN customers c
    ON scs.ss_customer_id = c.c_customer_id
ORDER BY scs.ss_store_id, rank_in_store
LIMIT 50
