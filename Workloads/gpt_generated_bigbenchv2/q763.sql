WITH all_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category AS category
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category AS category
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT category,
           SUM(quantity) AS total_quantity,
           SUM(quantity * price) AS total_revenue
    FROM all_sales
    GROUP BY category
),
review_agg AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.category,
       s.total_quantity,
       s.total_revenue,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.category = r.category
ORDER BY s.total_revenue DESC
LIMIT 10
