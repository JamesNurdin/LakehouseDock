WITH store_sales_agg AS (
    SELECT ss_item_id, SUM(ss_quantity) AS store_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id, SUM(ws_quantity) AS web_qty
    FROM web_sales
    GROUP BY ws_item_id
),
reviews_agg AS (
    SELECT pr_item_id,
           SUM(pr_sentiment) AS total_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    COALESCE(SUM(ss.store_qty), 0) AS store_quantity,
    COALESCE(SUM(ws.web_qty), 0) AS web_quantity,
    COALESCE(SUM(ss.store_qty), 0) + COALESCE(SUM(ws.web_qty), 0) AS total_quantity,
    CASE WHEN SUM(r.review_count) > 0
         THEN CAST(SUM(r.total_sentiment) AS double) / SUM(r.review_count)
         ELSE NULL
    END AS avg_sentiment,
    SUM(r.review_count) AS total_review_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN reviews_agg r ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
