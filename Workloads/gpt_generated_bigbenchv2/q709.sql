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
           SUM(pr_sentiment) AS total_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(sa.total_store_quantity, 0)) AS total_store_quantity,
       SUM(COALESCE(wa.total_web_quantity, 0)) AS total_web_quantity,
       SUM(COALESCE(ra.review_count, 0)) AS total_review_count,
       CASE WHEN SUM(COALESCE(ra.review_count, 0)) > 0
            THEN SUM(COALESCE(ra.total_sentiment, 0)) / SUM(COALESCE(ra.review_count, 0))
            ELSE NULL
       END AS avg_sentiment,
       AVG(i.i_price) AS avg_price
FROM items i
LEFT JOIN store_agg sa ON sa.ss_item_id = i.i_item_id
LEFT JOIN web_agg wa ON wa.ws_item_id = i.i_item_id
LEFT JOIN review_agg ra ON ra.pr_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY (SUM(COALESCE(sa.total_store_quantity, 0)) + SUM(COALESCE(wa.total_web_quantity, 0))) DESC
LIMIT 10
