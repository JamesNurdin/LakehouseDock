WITH combined_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT i.i_category_id,
           i.i_category,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT i_category_id,
           i_category,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT customer_id) AS total_customers
    FROM combined_sales
    GROUP BY i_category_id, i_category
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id AS category_id,
       s.i_category AS category,
       s.total_quantity,
       s.total_customers,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN reviews_agg r ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity DESC
LIMIT 10
