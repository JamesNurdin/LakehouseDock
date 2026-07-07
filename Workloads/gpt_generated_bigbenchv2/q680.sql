WITH store_agg AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
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
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       ra.avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count,
       (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_quantity DESC
LIMIT 10
