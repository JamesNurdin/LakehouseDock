WITH store_sales_agg AS (
    SELECT ss.ss_item_id AS item_id,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_agg AS (
    SELECT ws.ws_item_id AS item_id,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT pr.pr_item_id AS item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_category AS category,
       i.i_category_id AS category_id,
       SUM(COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0)) AS total_quantity_sold,
       CASE
           WHEN SUM(COALESCE(r.review_count, 0)) > 0
           THEN SUM(COALESCE(r.avg_sentiment, 0) * COALESCE(r.review_count, 0)) / SUM(COALESCE(r.review_count, 0))
           ELSE NULL
       END AS avg_review_sentiment,
       SUM(COALESCE(r.review_count, 0)) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg ssa ON ssa.item_id = i.i_item_id
LEFT JOIN web_sales_agg wsa ON wsa.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 100
