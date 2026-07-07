WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_store_id AS store_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity,
           ss_ts AS ts
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           NULL AS store_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity,
           ws_ts AS ts
    FROM web_sales
),
sales_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           SUM(cs.quantity) AS total_quantity,
           SUM(cs.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT cs.customer_id) AS distinct_customers
    FROM combined_sales cs
    JOIN items i
      ON cs.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_by_category AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT sbc.i_category_id,
       sbc.i_category,
       sbc.total_quantity,
       sbc.total_revenue,
       sbc.distinct_customers,
       rbc.avg_sentiment,
       rbc.review_count
FROM sales_by_category sbc
LEFT JOIN reviews_by_category rbc
  ON sbc.i_category_id = rbc.i_category_id
ORDER BY sbc.total_quantity DESC
LIMIT 20
