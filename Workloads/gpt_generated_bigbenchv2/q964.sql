WITH item_store_sales AS (
    SELECT
        ss_store_id,
        ss_item_id,
        sum(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
ranked_items AS (
    SELECT
        iss.ss_store_id,
        iss.ss_item_id,
        iss.total_quantity,
        row_number() OVER (PARTITION BY iss.ss_store_id ORDER BY iss.total_quantity DESC) AS item_rank
    FROM item_store_sales iss
)
SELECT
    s.s_store_name,
    ri.ss_item_id,
    ri.total_quantity,
    ri.item_rank
FROM ranked_items ri
JOIN stores s
    ON ri.ss_store_id = s.s_store_id
WHERE ri.item_rank <= 3
ORDER BY s.s_store_name, ri.item_rank
