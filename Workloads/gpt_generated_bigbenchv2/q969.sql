WITH review_stats AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category
),
sales_stats AS (
    SELECT
        i.i_item_id,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_quantity,
        COALESCE(SUM(ws.ws_quantity), 0) AS web_quantity,
        COALESCE(SUM(ss.ss_quantity), 0) + COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity
    FROM items i
    LEFT JOIN store_sales ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales ws ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    rs.i_item_id,
    rs.i_name,
    rs.i_category,
    rs.avg_sentiment,
    rs.review_count,
    s.store_quantity,
    s.web_quantity,
    s.total_quantity
FROM review_stats rs
JOIN sales_stats s ON s.i_item_id = rs.i_item_id
ORDER BY rs.avg_sentiment DESC, s.total_quantity DESC
LIMIT 10
