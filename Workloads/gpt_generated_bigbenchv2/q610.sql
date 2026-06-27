WITH sales_per_item AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_per_item AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        COUNT(*) AS review_count,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    COUNT(DISTINCT i.i_item_id) AS distinct_items,
    SUM(COALESCE(s.total_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(s.total_revenue, 0.0)) AS total_revenue,
    AVG(COALESCE(r.avg_rating, 0)) AS avg_item_rating,
    SUM(COALESCE(r.review_count, 0)) AS total_reviews,
    AVG(i.i_price) AS avg_item_price
FROM items i
LEFT JOIN sales_per_item s ON i.i_item_id = s.i_item_id
LEFT JOIN reviews_per_item r ON i.i_item_id = r.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
