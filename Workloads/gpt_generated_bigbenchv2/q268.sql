WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        ss.ss_item_id
),
ranked_items AS (
    SELECT
        ss_store_id,
        s_store_name,
        ss_item_id,
        total_quantity,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_id ORDER BY total_quantity DESC) AS item_rank
    FROM store_item_sales
)
SELECT
    ss_store_id,
    s_store_name,
    ss_item_id,
    total_quantity,
    transaction_count
FROM ranked_items
WHERE item_rank <= 5
ORDER BY ss_store_id, total_quantity DESC
