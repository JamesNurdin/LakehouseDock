WITH unified_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT us.customer_id) AS distinct_customers
    FROM unified_sales us
    JOIN items i ON us.item_id = i.i_item_id
    GROUP BY i.i_category
),
reviews_by_category AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_review_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT s.category,
       s.total_quantity,
       s.total_revenue,
       s.distinct_customers,
       r.avg_review_sentiment,
       r.review_count
FROM sales_by_category s
LEFT JOIN reviews_by_category r ON s.category = r.category
ORDER BY s.total_revenue DESC
LIMIT 10
