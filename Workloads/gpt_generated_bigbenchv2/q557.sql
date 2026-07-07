WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS total_store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS total_web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category AS category,
       i.i_category_id AS category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) AS total_quantity_sold,
       SUM(COALESCE(sa.total_store_qty, 0)) AS total_store_quantity,
       SUM(COALESCE(wa.total_web_qty, 0)) AS total_web_quantity,
       AVG(i.i_price) AS avg_price,
       AVG(ra.avg_sentiment) AS avg_sentiment,
       SUM(ra.review_count) AS total_reviews
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 20
