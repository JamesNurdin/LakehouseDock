WITH store_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
review_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category AS category,
    SUM(COALESCE(sa.total_store_qty, 0) + COALESCE(wa.total_web_qty, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.total_store_qty, 0)) AS total_store_quantity,
    SUM(COALESCE(wa.total_web_qty, 0)) AS total_web_quantity,
    CASE WHEN SUM(ra.review_cnt) > 0
         THEN SUM(ra.avg_sentiment * ra.review_cnt) / SUM(ra.review_cnt)
         ELSE NULL
    END AS weighted_average_sentiment,
    COUNT(DISTINCT i.i_item_id) AS distinct_items
FROM items i
LEFT JOIN store_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
