WITH combined_sales AS (
    SELECT ss_transaction_id AS transaction_id,
           ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_transaction_id AS transaction_id,
           ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           'web' AS channel
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category AS category,
           SUM(cs.quantity) AS total_quantity_sold,
           SUM(cs.quantity * i.i_price) AS total_revenue
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY i.i_category
),
category_reviews AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sbc.category,
       sbc.total_quantity_sold,
       sbc.total_revenue,
       cr.avg_sentiment,
       cr.review_count
FROM sales_by_category sbc
LEFT JOIN category_reviews cr ON sbc.category = cr.category
ORDER BY sbc.total_revenue DESC
