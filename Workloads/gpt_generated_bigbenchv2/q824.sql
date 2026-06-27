WITH
  offline_sales AS (
    SELECT
      i.i_category_id,
      i.i_category_name,
      SUM(ss.ss_quantity) AS offline_quantity,
      SUM(ss.ss_quantity * i.i_price) AS offline_revenue,
      COUNT(DISTINCT ss.ss_customer_id) AS offline_distinct_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
  ),
  online_sales AS (
    SELECT
      i.i_category_id,
      i.i_category_name,
      SUM(ws.ws_quantity) AS online_quantity,
      SUM(ws.ws_quantity * i.i_price) AS online_revenue,
      COUNT(DISTINCT ws.ws_customer_id) AS online_distinct_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
  ),
  category_ratings AS (
    SELECT
      i.i_category_id,
      i.i_category_name,
      AVG(pr.pr_rating) AS avg_rating,
      COUNT(pr.pr_review_id) AS total_reviews
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
  )
SELECT
  COALESCE(off.i_category_id, onl.i_category_id, rat.i_category_id) AS category_id,
  COALESCE(off.i_category_name, onl.i_category_name, rat.i_category_name) AS category_name,
  off.offline_quantity,
  onl.online_quantity,
  off.offline_revenue,
  onl.online_revenue,
  rat.avg_rating,
  rat.total_reviews,
  off.offline_distinct_customers,
  onl.online_distinct_customers
FROM offline_sales off
FULL OUTER JOIN online_sales onl
  ON off.i_category_id = onl.i_category_id
FULL OUTER JOIN category_ratings rat
  ON COALESCE(off.i_category_id, onl.i_category_id) = rat.i_category_id
ORDER BY (COALESCE(off.offline_revenue, 0) + COALESCE(onl.online_revenue, 0)) DESC
