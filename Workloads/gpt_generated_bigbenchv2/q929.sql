WITH base_categories AS (
  SELECT DISTINCT i.i_category_id,
         i.i_category_name
  FROM items i
),
category_review_agg AS (
  SELECT i.i_category_id,
         i.i_category_name,
         avg(pr.pr_rating) AS avg_rating
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
),
store_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category_name,
         SUM(ss.ss_quantity) AS store_quantity,
         SUM(ss.ss_quantity * i.i_price) AS store_revenue,
         COUNT(DISTINCT ss.ss_customer_id) AS store_customers,
         COUNT(DISTINCT ss.ss_store_id) AS store_count
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category_name,
         SUM(ws.ws_quantity) AS web_quantity,
         SUM(ws.ws_quantity * i.i_price) AS web_revenue,
         COUNT(DISTINCT ws.ws_customer_id) AS web_customers
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
)
SELECT
  bc.i_category_id AS category_id,
  bc.i_category_name AS category_name,
  coalesce(ss.store_quantity, 0) + coalesce(ws.web_quantity, 0) AS total_quantity,
  coalesce(ss.store_revenue, 0) + coalesce(ws.web_revenue, 0) AS total_revenue,
  cr.avg_rating,
  coalesce(ss.store_customers, 0) + coalesce(ws.web_customers, 0) AS total_customers,
  coalesce(ss.store_count, 0) AS store_count
FROM base_categories bc
LEFT JOIN store_sales_agg ss
  ON bc.i_category_id = ss.i_category_id
LEFT JOIN web_sales_agg ws
  ON bc.i_category_id = ws.i_category_id
LEFT JOIN category_review_agg cr
  ON bc.i_category_id = cr.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
