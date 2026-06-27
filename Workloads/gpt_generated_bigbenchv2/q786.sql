WITH unified_sales AS (
  SELECT
    ss.ss_item_id AS item_id,
    ss.ss_quantity AS quantity,
    ss.ss_customer_id AS customer_id,
    ss.ss_store_id AS store_id,
    'store' AS channel
  FROM store_sales ss
  UNION ALL
  SELECT
    ws.ws_item_id AS item_id,
    ws.ws_quantity AS quantity,
    ws.ws_customer_id AS customer_id,
    NULL AS store_id,
    'web' AS channel
  FROM web_sales ws
),

sales_agg AS (
  SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS total_store_quantity,
    SUM(CASE WHEN us.channel = 'web'   THEN us.quantity ELSE 0 END) AS total_web_quantity,
    SUM(CASE WHEN us.channel = 'store' THEN us.quantity * i.i_price ELSE 0 END) AS total_store_revenue,
    SUM(CASE WHEN us.channel = 'web'   THEN us.quantity * i.i_price ELSE 0 END) AS total_web_revenue,
    COUNT(DISTINCT CASE WHEN us.channel = 'store' THEN us.customer_id END) AS distinct_store_customers,
    COUNT(DISTINCT CASE WHEN us.channel = 'web'   THEN us.customer_id END) AS distinct_web_customers
  FROM unified_sales us
  JOIN items i ON us.item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category_name
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
  s.i_category_id AS category_id,
  s.i_category_name AS category_name,
  s.total_store_quantity,
  s.total_web_quantity,
  s.total_store_quantity + s.total_web_quantity AS total_quantity,
  s.total_store_revenue,
  s.total_web_revenue,
  s.total_store_revenue + s.total_web_revenue AS total_revenue,
  s.distinct_store_customers,
  s.distinct_web_customers,
  COALESCE(r.avg_rating, 0.0) AS avg_rating,
  COALESCE(r.review_count, 0) AS review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category_id = r.i_category_id
ORDER BY total_revenue DESC
LIMIT 20
