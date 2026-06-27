WITH store_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_quantity) AS avg_quantity,
        MAX(ss.ss_ts) AS latest_ts
    FROM store_sales ss
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    WHERE ss.ss_quantity > 0
    GROUP BY ss.ss_store_id, s.s_store_name
),
item_agg AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS item_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
top_item_per_store AS (
    SELECT
        ia.ss_store_id,
        ia.ss_item_id,
        ia.item_quantity,
        ROW_NUMBER() OVER (PARTITION BY ia.ss_store_id ORDER BY ia.item_quantity DESC) AS rn
    FROM item_agg ia
),
top_items AS (
    SELECT
        ss_store_id,
        ss_item_id AS top_item_id,
        item_quantity AS top_item_quantity
    FROM top_item_per_store
    WHERE rn = 1
)
SELECT
    sa.ss_store_id,
    sa.s_store_name,
    sa.total_quantity,
    sa.transaction_count,
    sa.avg_quantity,
    sa.latest_ts,
    ti.top_item_id,
    ti.top_item_quantity
FROM store_agg sa
JOIN top_items ti
    ON sa.ss_store_id = ti.ss_store_id
ORDER BY sa.total_quantity DESC
LIMIT 10
