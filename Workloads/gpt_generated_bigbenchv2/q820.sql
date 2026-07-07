WITH all_sales AS (
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
           i.i_category_id AS category_id,
           COUNT(DISTINCT s.customer_id) AS distinct_customers,
           SUM(s.quantity) AS total_units_sold,
           SUM(s.quantity * i.i_price) AS total_revenue
    FROM all_sales s
    JOIN items i ON s.item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
review_by_category AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT s.category,
       s.category_id,
       s.distinct_customers,
       s.total_units_sold,
       s.total_revenue,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_by_category s
LEFT JOIN review_by_category r
    ON s.category = r.category AND s.category_id = r.category_id
ORDER BY s.total_revenue DESC
LIMIT 10
