WITH sales_agg AS (
    SELECT
        ws.ws_item_id AS item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
),
reviews_agg AS (
    SELECT
        pr.pr_item_id AS item_id,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(s.total_quantity, 0)) AS category_total_quantity,
    SUM(COALESCE(s.total_revenue, 0)) AS category_total_revenue,
    AVG(r.avg_sentiment) AS category_avg_sentiment,
    SUM(COALESCE(r.review_count, 0)) AS category_review_count
FROM items i
LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category, i.i_category_id
ORDER BY category_total_revenue DESC
LIMIT 10
