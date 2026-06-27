WITH store_agg AS (
    SELECT
        ss.ss_item_id AS item_id,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
item_sales AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        COALESCE(sa.store_quantity, 0) AS store_quantity,
        COALESCE(wa.web_quantity, 0) AS web_quantity,
        COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
        (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) * i.i_price AS total_revenue
    FROM items i
    LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
    LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i_sales.i_category_id,
    i_sales.i_category_name,
    COUNT(DISTINCT i_sales.i_item_id) AS distinct_item_count,
    SUM(i_sales.store_quantity) AS total_store_quantity,
    SUM(i_sales.web_quantity) AS total_web_quantity,
    SUM(i_sales.total_quantity) AS total_quantity_sold,
    SUM(i_sales.total_revenue) AS total_revenue,
    AVG(ir.avg_rating) AS avg_item_rating,
    SUM(ir.review_count) AS total_review_count
FROM item_sales i_sales
LEFT JOIN item_ratings ir ON ir.item_id = i_sales.i_item_id
GROUP BY i_sales.i_category_id, i_sales.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
