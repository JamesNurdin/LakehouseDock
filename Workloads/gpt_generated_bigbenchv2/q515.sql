WITH sales AS (
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
),
web AS (
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
),
sales_combined AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM web
),
reviews AS (
    SELECT i.i_category_id,
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
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.quantity * s.price) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS distinct_customers,
    r.avg_sentiment,
    r.review_count
FROM sales_combined s
LEFT JOIN reviews r ON s.i_category_id = r.i_category_id
GROUP BY s.i_category_id, s.i_category, r.avg_sentiment, r.review_count
ORDER BY total_revenue DESC
