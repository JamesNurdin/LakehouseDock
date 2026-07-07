WITH unified_sales AS (
    SELECT i.i_category AS i_category,
           ss.ss_quantity AS quantity,
           i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category AS i_category,
           ws.ws_quantity AS quantity,
           i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_by_category AS (
    SELECT i_category,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM unified_sales
    GROUP BY i_category
),
reviews_by_category AS (
    SELECT i.i_category AS i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    s.total_quantity,
    s.total_revenue,
    r.avg_sentiment,
    r.review_count
FROM sales_by_category s
LEFT JOIN reviews_by_category r ON r.i_category = s.i_category
ORDER BY s.total_revenue DESC
