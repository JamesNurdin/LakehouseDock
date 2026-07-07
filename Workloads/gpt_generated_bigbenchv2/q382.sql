WITH sales_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(i.i_price * ws.ws_quantity) AS total_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
review_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    s.i_category_id,
    s.i_category,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    r.avg_sentiment,
    r.review_count
FROM sales_by_category s
LEFT JOIN review_by_category r
    ON s.i_category_id = r.i_category_id
ORDER BY s.total_revenue DESC
LIMIT 10
