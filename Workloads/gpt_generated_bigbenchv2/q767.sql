WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
)
SELECT
    i.i_category AS category,
    i.i_category_id AS category_id,
    SUM(COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity_sold,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
FROM items i
LEFT JOIN store_sales_agg ss ON i.i_item_id = ss.ss_item_id
LEFT JOIN web_sales_agg ws ON i.i_item_id = ws.ws_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
