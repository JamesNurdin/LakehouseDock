WITH sales_by_customer_store AS (
    SELECT
        ss_customer_id,
        ss_store_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss_transaction_id) AS transaction_count,
        COUNT(DISTINCT ss_item_id) AS distinct_items
    FROM store_sales
    GROUP BY ss_customer_id, ss_store_id
),
ranked_sales AS (
    SELECT
        ss_customer_id,
        ss_store_id,
        total_quantity,
        transaction_count,
        distinct_items,
        ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS rank_in_store
    FROM sales_by_customer_store
)
SELECT
    c.c_customer_id,
    c.c_name,
    r.ss_store_id,
    r.total_quantity,
    r.transaction_count,
    r.distinct_items,
    r.rank_in_store
FROM ranked_sales r
JOIN customers c
    ON r.ss_customer_id = c.c_customer_id
WHERE r.rank_in_store <= 5
ORDER BY r.ss_store_id, r.rank_in_store
