WITH customer_store_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        c.c_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        COUNT(DISTINCT ss.ss_item_id) AS distinct_items
    FROM store_sales ss
    JOIN customers c
        ON ss.ss_customer_id = c.c_customer_id
    GROUP BY ss.ss_store_id, ss.ss_customer_id, c.c_name
),
ranked_customers AS (
    SELECT
        cs.ss_store_id,
        cs.ss_customer_id,
        cs.c_name,
        cs.total_quantity,
        cs.transaction_count,
        cs.distinct_items,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_store_id ORDER BY cs.total_quantity DESC) AS store_rank
    FROM customer_store_sales cs
)
SELECT
    rc.ss_store_id,
    rc.ss_customer_id,
    rc.c_name,
    rc.total_quantity,
    rc.transaction_count,
    rc.distinct_items
FROM ranked_customers rc
WHERE rc.store_rank = 1
ORDER BY rc.total_quantity DESC
