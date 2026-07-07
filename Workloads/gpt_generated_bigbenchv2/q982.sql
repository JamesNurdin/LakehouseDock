WITH store_sales_agg AS (
    SELECT ss_item_id, SUM(ss_quantity) AS ss_qty
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT ws_item_id, SUM(ws_quantity) AS ws_qty
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(ss.ss_qty, 0) + COALESCE(ws.ws_qty, 0)) AS total_quantity,
    SUM((COALESCE(ss.ss_qty, 0) + COALESCE(ws.ws_qty, 0)) * i.i_price) AS total_revenue,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(DISTINCT pr.pr_review_id) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
