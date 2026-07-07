WITH sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_store_id AS store_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           NULL AS store_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
)
SELECT i.i_category,
       s.channel,
       SUM(s.quantity) AS total_quantity,
       COUNT(DISTINCT s.customer_id) AS distinct_customers,
       AVG(pr.pr_sentiment) AS avg_sentiment,
       COUNT(DISTINCT pr.pr_review_id) AS review_count
FROM sales s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
WHERE i.i_price > 10
GROUP BY i.i_category, s.channel
ORDER BY total_quantity DESC
LIMIT 10
