WITH offline_sales AS (
    SELECT ss_item_id,
           SUM(ss_quantity) AS offline_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
online_sales AS (
    SELECT ws_item_id,
           SUM(ws_quantity) AS online_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_per_item AS (
    SELECT pr_item_id,
           SUM(pr_sentiment) AS total_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category,
       SUM(COALESCE(os.offline_quantity, 0)) AS total_offline_quantity,
       SUM(COALESCE(onl.online_quantity, 0)) AS total_online_quantity,
       CASE WHEN SUM(COALESCE(r.review_count, 0)) > 0
            THEN SUM(COALESCE(r.total_sentiment, 0)) / SUM(COALESCE(r.review_count, 0))
            ELSE NULL
       END AS avg_sentiment,
       SUM(COALESCE(r.review_count, 0)) AS total_reviews
FROM items i
LEFT JOIN offline_sales os ON os.ss_item_id = i.i_item_id
LEFT JOIN online_sales onl ON onl.ws_item_id = i.i_item_id
LEFT JOIN reviews_per_item r ON r.pr_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY i.i_category
