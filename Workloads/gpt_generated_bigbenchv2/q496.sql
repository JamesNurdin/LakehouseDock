WITH all_sales AS (
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
SELECT i.i_category,
       i.i_category_id,
       COUNT(DISTINCT i.i_item_id) AS distinct_items,
       SUM(a.quantity) AS total_quantity_sold,
       AVG(i.i_price) AS avg_item_price,
       AVG(pr.pr_sentiment) AS avg_review_sentiment,
       COUNT(DISTINCT a.customer_id) AS total_distinct_customers
FROM all_sales a
JOIN items i
    ON a.item_id = i.i_item_id
LEFT JOIN product_reviews pr
    ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category,
         i.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
