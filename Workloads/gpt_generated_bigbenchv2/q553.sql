WITH store_item_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        SUM(ss.ss_quantity) * 1.0 / COUNT(DISTINCT ss.ss_transaction_id) AS avg_quantity_per_transaction
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, ss.ss_item_id
)
SELECT
    s_store_name,
    ss_item_id,
    total_quantity,
    transaction_count,
    avg_quantity_per_transaction
FROM store_item_agg
ORDER BY total_quantity DESC
LIMIT 10
