WITH review_stats AS (
    SELECT
        pr.pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_stats AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity
    FROM store_sales ss
    GROUP BY ss.ss_item_id
),
web_sales_stats AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_category_id,
    i.i_category,
    i.i_name,
    i.i_price,
    i.i_comp_price,
    COALESCE(rs.review_count, 0) AS review_count,
    COALESCE(rs.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(sss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(wss.total_web_quantity, 0) AS total_web_quantity
FROM items i
LEFT JOIN review_stats rs ON rs.pr_item_id = i.i_item_id
LEFT JOIN store_sales_stats sss ON sss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_stats wss ON wss.ws_item_id = i.i_item_id
ORDER BY avg_sentiment DESC
LIMIT 20
