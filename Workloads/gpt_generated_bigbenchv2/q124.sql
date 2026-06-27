WITH review_stats AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating,
        SUM(CASE WHEN pr_rating >= 4 THEN 1 ELSE 0 END) AS high_rating_count
    FROM product_reviews
    GROUP BY pr_item_id
),
sales_stats AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_item_count,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(s.total_revenue), 0) AS total_revenue,
    SUM(r.avg_rating * r.review_count) / NULLIF(SUM(r.review_count), 0) AS avg_category_rating,
    COALESCE(SUM(r.review_count), 0) AS total_review_count,
    COALESCE(SUM(r.high_rating_count), 0) AS high_rating_review_count
FROM items i
LEFT JOIN review_stats r ON r.pr_item_id = i.i_item_id
LEFT JOIN sales_stats s ON s.ws_item_id = i.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
