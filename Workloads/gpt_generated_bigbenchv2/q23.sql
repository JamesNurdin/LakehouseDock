WITH sales AS (
    SELECT ss_item_id AS item_id,
           ss_customer_id AS customer_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id,
           ws_customer_id AS customer_id,
           ws_quantity AS quantity
    FROM web_sales
),
category_sales AS (
    SELECT i.i_category AS category,
           SUM(s.quantity) AS total_quantity,
           SUM(s.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT s.customer_id) AS distinct_customers
    FROM sales s
    JOIN items i
        ON s.item_id = i.i_item_id
    GROUP BY i.i_category
),
category_sentiment AS (
    SELECT i.i_category AS category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT cs.category,
       cs.total_quantity,
       cs.total_revenue,
       cs.distinct_customers,
       COALESCE(csnt.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(csnt.review_count, 0) AS review_count
FROM category_sales cs
LEFT JOIN category_sentiment csnt
    ON cs.category = csnt.category
ORDER BY cs.total_revenue DESC
LIMIT 10
