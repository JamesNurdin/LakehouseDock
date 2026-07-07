WITH sales AS (
    SELECT i.i_category,
           i.i_category_id,
           i.i_price,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category,
           i.i_category_id,
           i.i_price,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
review_agg AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    s.i_category_id,
    SUM(s.quantity) AS total_quantity_sold,
    COUNT(DISTINCT s.customer_id) AS distinct_customers,
    SUM(s.i_price * s.quantity) / NULLIF(SUM(s.quantity), 0) AS weighted_avg_price,
    r.avg_sentiment,
    r.review_count
FROM sales s
LEFT JOIN review_agg r ON s.i_category = r.i_category
GROUP BY s.i_category, s.i_category_id, r.avg_sentiment, r.review_count
ORDER BY total_quantity_sold DESC
LIMIT 10
