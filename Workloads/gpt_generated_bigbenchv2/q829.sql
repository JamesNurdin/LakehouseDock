WITH store_sales_cte AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_cte AS (
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
    SELECT * FROM store_sales_cte
    UNION ALL
    SELECT * FROM web_sales_cte
),
review_stats AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category,
    SUM(s.quantity) AS total_quantity,
    SUM(s.quantity * s.price) AS total_revenue,
    COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
    COALESCE(r.review_count, 0) AS review_count
FROM all_sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN review_stats r ON i.i_item_id = r.item_id
GROUP BY i.i_item_id, i.i_name, i.i_category, r.avg_sentiment, r.review_count
ORDER BY total_revenue DESC
LIMIT 10
