WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
category_sales AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(cs.quantity) AS total_quantity,
           SUM(i.i_price * cs.quantity) / NULLIF(SUM(cs.quantity), 0) AS avg_weighted_price,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers,
           AVG(pr.pr_sentiment) AS avg_review_sentiment
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT i_category_id,
       i_category,
       total_quantity,
       avg_weighted_price,
       distinct_customers,
       avg_review_sentiment
FROM category_sales
ORDER BY total_quantity DESC
LIMIT 20
