WITH store_agg AS (
    SELECT ss_item_id,
           ss_store_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id, ss_store_id
),
web_agg AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS web_quantity
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
       s.s_store_name,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM store_agg sa
JOIN items i ON sa.ss_item_id = i.i_item_id
JOIN stores s ON sa.ss_store_id = s.s_store_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
ORDER BY total_quantity DESC
LIMIT 100
