WITH avg_sentiment AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
),
combined_sales AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS revenue,
           ss.ss_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS revenue,
           ws.ws_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
)
SELECT i.i_category,
       SUM(cs.quantity) AS total_quantity_sold,
       SUM(cs.revenue) AS total_revenue,
       COUNT(DISTINCT cs.customer_id) AS distinct_customers,
       AVG(avg_s.avg_sentiment) AS avg_review_sentiment
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN avg_sentiment avg_s ON avg_s.pr_item_id = i.i_item_id
GROUP BY i.i_category
ORDER BY total_revenue DESC
