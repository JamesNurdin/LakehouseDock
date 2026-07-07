WITH all_sales AS (
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
sales_with_customer AS (
    SELECT a.item_id,
           a.customer_id,
           a.quantity
    FROM all_sales a
    JOIN customers c
      ON a.customer_id = c.c_customer_id
),
sales_agg AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           SUM(swc.quantity) AS total_quantity,
           SUM(swc.quantity * i.i_price) AS total_revenue,
           COUNT(DISTINCT swc.customer_id) AS distinct_customers
    FROM sales_with_customer swc
    JOIN items i
      ON swc.item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
),
reviews_agg AS (
    SELECT i.i_category AS category,
           i.i_category_id AS category_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT s.category,
       s.category_id,
       s.total_quantity,
       s.total_revenue,
       s.distinct_customers,
       COALESCE(r.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN reviews_agg r
  ON s.category = r.category
 AND s.category_id = r.category_id
ORDER BY s.total_revenue DESC
LIMIT 10
