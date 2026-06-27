WITH store_item_sales AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS item_total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
ranked_items AS (
    SELECT
        si.ss_store_id,
        si.ss_item_id,
        si.item_total_quantity,
        ROW_NUMBER() OVER (PARTITION BY si.ss_store_id ORDER BY si.item_total_quantity DESC) AS rn
    FROM store_item_sales si
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ri.ss_item_id,
    ri.item_total_quantity
FROM ranked_items ri
JOIN stores s ON ri.ss_store_id = s.s_store_id
WHERE ri.rn <= 3
ORDER BY s.s_store_id, ri.item_total_quantity DESC
