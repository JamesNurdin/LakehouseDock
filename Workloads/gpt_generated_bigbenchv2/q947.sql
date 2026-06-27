WITH combined_sales AS (
    -- Combine in‑store and online sales, preserving the store identifier for in‑store rows
    SELECT ss_item_id AS item_id,
           ss_store_id AS store_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           NULL AS store_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_item AS (
    -- Aggregate quantity per item (and per store when applicable)
    SELECT cs.item_id,
           cs.store_id,
           SUM(cs.quantity) AS total_quantity
    FROM combined_sales cs
    GROUP BY cs.item_id, cs.store_id
),
item_reviews AS (
    -- Compute average rating and review count per item
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    COALESCE(s.s_store_id, -1) AS store_id,
    COALESCE(s.s_store_name, 'Online') AS store_name,
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(sbi.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(sbi.total_quantity, 0) * i.i_price) AS total_revenue,
    AVG(COALESCE(ir.avg_rating, 0)) AS avg_item_rating,
    SUM(COALESCE(ir.review_count, 0)) AS total_reviews
FROM sales_by_item sbi
JOIN items i ON i.i_item_id = sbi.item_id
LEFT JOIN stores s ON s.s_store_id = sbi.store_id
LEFT JOIN item_reviews ir ON ir.pr_item_id = i.i_item_id
GROUP BY
    COALESCE(s.s_store_id, -1),
    COALESCE(s.s_store_name, 'Online'),
    i.i_category_id,
    i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 20
