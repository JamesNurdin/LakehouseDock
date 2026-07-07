WITH combined_sales AS (
  SELECT
    ss.ss_customer_id AS c_customer_id,
    i.i_category_id,
    i.i_category,
    ss.ss_quantity AS quantity,
    i.i_price * ss.ss_quantity AS revenue
  FROM store_sales ss
  JOIN customers c ON ss.ss_customer_id = c.c_customer_id
  JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_combined AS (
  SELECT
    ws.ws_customer_id AS c_customer_id,
    i.i_category_id,
    i.i_category,
    ws.ws_quantity AS quantity,
    i.i_price * ws.ws_quantity AS revenue
  FROM web_sales ws
  JOIN customers c ON ws.ws_customer_id = c.c_customer_id
  JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
  SELECT * FROM combined_sales
  UNION ALL
  SELECT * FROM web_sales_combined
),
category_sales AS (
  SELECT
    i_category_id,
    i_category,
    SUM(quantity) AS total_quantity,
    SUM(revenue) AS total_revenue,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
  FROM all_sales
  GROUP BY i_category_id, i_category
),
category_reviews AS (
  SELECT
    i.i_category_id,
    i.i_category,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(*) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
)
SELECT
  cs.i_category_id,
  cs.i_category,
  cs.total_quantity,
  cs.total_revenue,
  cs.distinct_customers,
  cr.avg_sentiment,
  cr.review_count
FROM category_sales cs
LEFT JOIN category_reviews cr
  ON cs.i_category_id = cr.i_category_id
ORDER BY cs.total_revenue DESC
LIMIT 20
