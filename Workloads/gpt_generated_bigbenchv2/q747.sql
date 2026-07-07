WITH store_sales_agg AS (
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
),
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category,
           COALESCE(ssa.store_quantity, 0) AS store_quantity,
           COALESCE(wsa.web_quantity, 0) AS web_quantity,
           COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales_agg ssa ON ssa.i_item_id = i.i_item_id
    LEFT JOIN web_sales_agg wsa ON wsa.i_item_id = i.i_item_id
),
item_reviews AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM items i
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT isales.i_item_id,
       isales.i_name,
       isales.i_category,
       isales.store_quantity,
       isales.web_quantity,
       isales.total_quantity,
       irev.avg_sentiment,
       irev.review_count
FROM item_sales isales
JOIN item_reviews irev ON irev.i_item_id = isales.i_item_id
ORDER BY isales.total_quantity DESC, irev.avg_sentiment DESC
LIMIT 10
