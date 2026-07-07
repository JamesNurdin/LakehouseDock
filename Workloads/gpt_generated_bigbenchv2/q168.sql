WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_customer_id AS customer_id
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_customer_id AS customer_id
    FROM web_sales
),
sales_agg_by_category AS (
    SELECT i.i_category AS category,
           SUM(s.quantity) AS total_quantity_sold,
           COUNT(DISTINCT s.customer_id) AS unique_customers
    FROM sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category
),
review_agg_by_category AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.category,
       s.total_quantity_sold,
       s.unique_customers,
       r.avg_sentiment,
       r.review_count
FROM sales_agg_by_category s
LEFT JOIN review_agg_by_category r ON s.category = r.category
ORDER BY s.total_quantity_sold DESC
LIMIT 5
