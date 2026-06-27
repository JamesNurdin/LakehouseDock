WITH item_sales AS (
    SELECT
        ss_store_id,
        ss_item_id,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
ranked_items AS (
    SELECT
        ss_store_id,
        ss_item_id,
        total_quantity,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS rank_per_store
    FROM item_sales
)
SELECT
    s.s_store_id,
    s.s_store_name,
    r.ss_item_id,
    r.total_quantity,
    r.transaction_count,
    r.rank_per_store
FROM stores s
JOIN ranked_items r
    ON s.s_store_id = r.ss_store_id
WHERE r.rank_per_store <= 3
ORDER BY s.s_store_id, r.rank_per_store
