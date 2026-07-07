WITH sales AS (
    SELECT
        ws.ws_transaction_id,
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_item_id,
        i.i_category_id,
        i.i_category,
        i.i_price
    FROM web_sales ws
    INNER JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    INNER JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT
    s.i_category_id,
    s.i_category,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_quantity * s.i_price) AS total_revenue,
    COUNT(DISTINCT s.ws_customer_id) AS distinct_customers,
    AVG(pr.pr_sentiment) AS avg_review_sentiment,
    COUNT(pr.pr_review_id) AS review_count
FROM sales s
LEFT JOIN product_reviews pr ON pr.pr_item_id = s.i_item_id
GROUP BY s.i_category_id, s.i_category
ORDER BY total_revenue DESC
LIMIT 10
