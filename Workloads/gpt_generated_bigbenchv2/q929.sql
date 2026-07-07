WITH sales_union AS (
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
product_review_agg AS (
    SELECT pr_item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_category_id,
       i.i_category,
       SUM(s.quantity) AS total_quantity,
       SUM(i.i_price * s.quantity) AS total_revenue,
       AVG(pr.avg_sentiment) AS avg_review_sentiment,
       COUNT(DISTINCT s.customer_id) AS distinct_customers
FROM sales_union s
JOIN items i ON s.item_id = i.i_item_id
LEFT JOIN product_review_agg pr ON i.i_item_id = pr.pr_item_id
GROUP BY i.i_category_id, i.i_category
ORDER BY total_revenue DESC
LIMIT 10
