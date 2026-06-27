WITH sales AS (
  SELECT
    ss.ss_transaction_id AS transaction_id,
    ss.ss_customer_id AS customer_id,
    ss.ss_item_id AS item_id,
    ss.ss_quantity AS quantity,
    'store' AS channel,
    s.s_store_name AS store_name
  FROM store_sales ss
  JOIN stores s
    ON ss.ss_store_id = s.s_store_id
  UNION ALL
  SELECT
    ws.ws_transaction_id AS transaction_id,
    ws.ws_customer_id AS customer_id,
    ws.ws_item_id AS item_id,
    ws.ws_quantity AS quantity,
    'web' AS channel,
    NULL AS store_name
  FROM web_sales ws
),
item_ratings AS (
  SELECT
    i.i_item_id,
    AVG(pr.pr_rating) AS avg_rating,
    COUNT(pr.pr_review_id) AS review_count
  FROM items i
  LEFT JOIN product_reviews pr
    ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_item_id
)
SELECT
  i.i_category_id,
  i.i_category_name,
  s.channel,
  MAX(s.store_name) AS store_name,
  COUNT(DISTINCT s.customer_id) AS distinct_customers,
  SUM(s.quantity) AS total_quantity,
  SUM(s.quantity * i.i_price) AS total_revenue,
  AVG(ir.avg_rating) AS avg_item_rating,
  SUM(ir.review_count) AS total_reviews
FROM sales s
JOIN items i
  ON s.item_id = i.i_item_id
LEFT JOIN item_ratings ir
  ON i.i_item_id = ir.i_item_id
GROUP BY
  i.i_category_id,
  i.i_category_name,
  s.channel
ORDER BY total_revenue DESC
