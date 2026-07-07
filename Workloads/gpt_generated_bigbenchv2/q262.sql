WITH unified_sales AS (
    SELECT ss_transaction_id AS transaction_id,
           ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_ts AS ts,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_transaction_id AS transaction_id,
           ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_ts AS ts,
           'web' AS channel
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category,
           us.channel,
           SUM(us.quantity) AS total_quantity,
           SUM(us.quantity * i.i_price) AS total_revenue
    FROM unified_sales us
    JOIN items i ON us.item_id = i.i_item_id
    GROUP BY i.i_category, us.channel
),
reviews_by_category AS (
    SELECT i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT sbc.i_category,
       sbc.channel,
       sbc.total_quantity,
       sbc.total_revenue,
       rbc.avg_sentiment,
       rbc.review_count
FROM sales_by_category sbc
LEFT JOIN reviews_by_category rbc ON sbc.i_category = rbc.i_category
ORDER BY sbc.total_revenue DESC
