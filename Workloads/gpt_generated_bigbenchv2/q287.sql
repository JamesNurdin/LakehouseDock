WITH
  store_sales_by_store_cat AS (
    SELECT
      s.s_store_id,
      s.s_store_name,
      i.i_category_id,
      i.i_category_name,
      SUM(ss.ss_quantity) AS total_store_quantity,
      COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
  ),
  web_sales_by_cat AS (
    SELECT
      i.i_category_id,
      i.i_category_name,
      SUM(ws.ws_quantity) AS total_web_quantity,
      COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    GROUP BY i.i_category_id, i.i_category_name
  ),
  reviews_by_cat AS (
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
  s.s_store_id,
  s.s_store_name,
  s.i_category_id,
  s.i_category_name,
  s.total_store_quantity,
  COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
  s.total_store_quantity + COALESCE(w.total_web_quantity, 0) AS total_quantity,
  s.distinct_store_customers + COALESCE(w.distinct_web_customers, 0) AS distinct_customers,
  COALESCE(r.avg_rating, 0) AS avg_rating,
  COALESCE(r.review_count, 0) AS review_count
FROM store_sales_by_store_cat s
LEFT JOIN web_sales_by_cat w
  ON s.i_category_id = w.i_category_id
LEFT JOIN reviews_by_cat r
  ON s.i_category_id = r.i_category_id
ORDER BY total_quantity DESC
LIMIT 20
