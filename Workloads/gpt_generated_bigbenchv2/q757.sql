WITH store_sales_agg AS (
  SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(i.i_price * ss.ss_quantity) AS store_revenue,
    COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count,
    COUNT(DISTINCT ss.ss_store_id) AS store_count
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
  SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(ws.ws_quantity) AS web_quantity,
    SUM(i.i_price * ws.ws_quantity) AS web_revenue,
    COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
),
customer_agg AS (
  SELECT
    u.i_category_id,
    u.i_category_name,
    COUNT(DISTINCT u.c_id) AS total_customer_count
  FROM (
    SELECT ss.ss_customer_id AS c_id, i.i_category_id, i.i_category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_customer_id AS c_id, i.i_category_id, i.i_category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
  ) u
  GROUP BY u.i_category_id, u.i_category_name
),
review_agg AS (
  SELECT
    i.i_category_id,
    i.i_category_name,
    AVG(pr.pr_rating) AS avg_rating,
    COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
)
SELECT
  COALESCE(ss.i_category_id, ws.i_category_id, ca.i_category_id, rv.i_category_id) AS category_id,
  COALESCE(ss.i_category_name, ws.i_category_name, ca.i_category_name, rv.i_category_name) AS category_name,
  ss.store_quantity,
  ws.web_quantity,
  (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
  ss.store_revenue,
  ws.web_revenue,
  (COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue,
  ss.store_customer_count,
  ws.web_customer_count,
  ca.total_customer_count,
  ss.store_count,
  rv.avg_rating,
  rv.review_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
  ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN customer_agg ca
  ON COALESCE(ss.i_category_id, ws.i_category_id) = ca.i_category_id
FULL OUTER JOIN review_agg rv
  ON COALESCE(ss.i_category_id, ws.i_category_id, ca.i_category_id) = rv.i_category_id
ORDER BY total_quantity DESC
LIMIT 20
