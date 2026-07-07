WITH store_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(sa.store_quantity, 0) AS store_quantity,
       COALESCE(wa.web_quantity, 0) AS web_quantity,
       (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity,
       ra.avg_sentiment
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
ORDER BY total_quantity DESC
LIMIT 10
