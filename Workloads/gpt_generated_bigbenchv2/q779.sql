WITH combined_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id AS item_id,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id AS item_id,
           ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
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
review_agg AS (
    SELECT i.i_category_id,
           i.i_category,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT s.i_category_id,
       s.i_category,
       s.total_quantity,
       s.total_revenue,
       s.distinct_customers,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_category_id = r.i_category_id
ORDER BY s.total_revenue DESC
