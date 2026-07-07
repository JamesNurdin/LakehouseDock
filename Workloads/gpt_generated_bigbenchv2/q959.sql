WITH store_agg AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS total_store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS total_web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(sa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wa.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(sa.total_store_quantity, 0) + COALESCE(wa.total_web_quantity, 0) AS total_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
WHERE i.i_price > 10.00
ORDER BY total_quantity DESC
LIMIT 10
