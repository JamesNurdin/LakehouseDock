WITH store_item_sales AS (
    SELECT
        ss_item_id AS item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_item_sales AS (
    SELECT
        ws_item_id AS item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
item_ratings AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_details AS (
    SELECT
        i_item_id,
        i_name,
        i_category_id,
        i_category_name,
        i_price,
        i_comp_price,
        i_class_id
    FROM items
)
SELECT
    d.i_item_id,
    d.i_name,
    d.i_category_name,
    d.i_price,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity
FROM item_details d
LEFT JOIN store_item_sales s ON s.item_id = d.i_item_id
LEFT JOIN web_item_sales w ON w.item_id = d.i_item_id
LEFT JOIN item_ratings r ON r.item_id = d.i_item_id
ORDER BY total_quantity DESC
LIMIT 100
