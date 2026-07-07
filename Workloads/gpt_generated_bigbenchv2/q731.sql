WITH review_stats AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY pr.pr_item_id
),
store_sales_stats AS (
    SELECT
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
web_sales_stats AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    i.i_item_id,
    i.i_name,
    COALESCE(rs.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(rs.review_count, 0) AS review_count,
    COALESCE(sss.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(sss.distinct_store_customers, 0) AS distinct_store_customers,
    COALESCE(wss.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(wss.distinct_web_customers, 0) AS distinct_web_customers
FROM items i
LEFT JOIN review_stats rs ON rs.pr_item_id = i.i_item_id
LEFT JOIN store_sales_stats sss ON sss.ss_item_id = i.i_item_id
LEFT JOIN web_sales_stats wss ON wss.ws_item_id = i.i_item_id
ORDER BY i.i_category_id, i.i_item_id
