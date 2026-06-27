WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
item_ratings AS (
    SELECT
        pr.pr_item_id AS item_id,
        SUM(pr.pr_rating) AS rating_sum,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.revenue) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS distinct_customers,
    CASE WHEN SUM(r.review_count) > 0 THEN SUM(r.rating_sum) / SUM(r.review_count) ELSE NULL END AS avg_rating,
    SUM(r.review_count) AS total_reviews
FROM sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN item_ratings r ON i.i_item_id = r.item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
