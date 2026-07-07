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
review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0)) AS total_quantity,
       AVG(r.avg_sentiment) AS avg_sentiment,
       SUM(r.review_count) AS total_reviews
FROM items i
LEFT JOIN store_sales_agg ss
    ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws
    ON i.i_item_id = ws.ws_item_id
LEFT JOIN review_agg r
    ON i.i_item_id = r.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity DESC
LIMIT 10
