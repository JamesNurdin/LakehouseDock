WITH sales_agg AS (
    SELECT
        i.i_category,
        SUM(ws.ws_quantity) AS total_units_sold,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category
),
review_agg AS (
    SELECT
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_review_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    s.total_units_sold,
    s.distinct_customers,
    r.avg_review_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category = r.i_category
ORDER BY s.total_units_sold DESC
