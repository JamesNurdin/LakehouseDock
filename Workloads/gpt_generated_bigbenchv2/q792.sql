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
)
SELECT i.i_category_id,
       i.i_category,
       SUM(s.quantity) AS total_quantity_sold,
       COUNT(DISTINCT s.customer_id) AS distinct_customers,
       AVG(pr.pr_sentiment) AS avg_review_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 20
