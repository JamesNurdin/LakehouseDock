WITH combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_customer_id AS customer_id,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category AS category,
           i.i_name AS item_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_customer_id AS customer_id,
           i.i_price AS price,
           i.i_category_id AS category_id,
           i.i_category AS category,
           i.i_name AS item_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
)
SELECT cs.category_id,
       cs.category,
       cs.item_id,
       cs.item_name,
       SUM(cs.quantity) AS total_quantity_sold,
       SUM(cs.quantity * cs.price) AS total_revenue,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       AVG(pr.pr_sentiment) AS avg_review_sentiment,
       COUNT(pr.pr_review_id) AS review_count
FROM combined_sales cs
LEFT JOIN product_reviews pr ON pr.pr_item_id = cs.item_id
GROUP BY cs.category_id,
         cs.category,
         cs.item_id,
         cs.item_name
ORDER BY total_revenue DESC
LIMIT 10
