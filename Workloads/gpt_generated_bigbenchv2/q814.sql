WITH review_agg AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_agg AS (
    SELECT ss.ss_item_id AS i_item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS i_item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
)
SELECT i.i_category,
       i.i_item_id,
       i.i_name,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count,
       COALESCE(ss.store_quantity, 0) AS store_quantity,
       COALESCE(ws.web_quantity, 0) AS web_quantity,
       COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity
FROM items i
LEFT JOIN review_agg r ON r.i_item_id = i.i_item_id
LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
ORDER BY avg_sentiment DESC
LIMIT 100
