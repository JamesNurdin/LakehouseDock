WITH item_reviews AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
item_store_sales AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
item_web_sales AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_category_name,
    i.i_category_id,
    i.i_price,
    i.i_comp_price,
    i.i_price - i.i_comp_price AS price_diff,
    COALESCE(sr.store_quantity, 0) AS store_quantity,
    COALESCE(wr.web_quantity, 0) AS web_quantity,
    COALESCE(sr.store_quantity, 0) + COALESCE(wr.web_quantity, 0) AS total_quantity,
    (COALESCE(sr.store_quantity, 0) + COALESCE(wr.web_quantity, 0)) * i.i_price AS total_revenue,
    ir.avg_rating,
    ir.review_count
FROM items i
LEFT JOIN item_reviews ir ON ir.i_item_id = i.i_item_id
LEFT JOIN item_store_sales sr ON sr.i_item_id = i.i_item_id
LEFT JOIN item_web_sales wr ON wr.i_item_id = i.i_item_id
WHERE i.i_price > 0
ORDER BY total_quantity DESC
LIMIT 100
