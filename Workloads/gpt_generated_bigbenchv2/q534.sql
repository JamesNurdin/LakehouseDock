WITH item_reviews AS (
  SELECT
    pr.pr_item_id AS item_id,
    AVG(pr.pr_sentiment) AS avg_sentiment
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
),
store_item_sales AS (
  SELECT
    ss.ss_store_id AS store_id,
    ss.ss_item_id AS item_id,
    SUM(ss.ss_quantity) AS quantity,
    SUM(ss.ss_quantity * i.i_price) AS revenue
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY ss.ss_store_id, ss.ss_item_id
),
store_sales_summary AS (
  SELECT
    sis.store_id,
    SUM(sis.quantity) AS total_quantity,
    SUM(sis.revenue) AS total_revenue,
    SUM(sis.quantity * COALESCE(ir.avg_sentiment, 0)) / NULLIF(SUM(sis.quantity), 0) AS weighted_avg_sentiment
  FROM store_item_sales sis
  LEFT JOIN item_reviews ir ON sis.item_id = ir.item_id
  GROUP BY sis.store_id
)
SELECT
  s.s_store_id,
  s.s_store_name,
  ss.total_quantity,
  ss.total_revenue,
  ss.weighted_avg_sentiment
FROM stores s
JOIN store_sales_summary ss ON s.s_store_id = ss.store_id
ORDER BY ss.total_revenue DESC
LIMIT 10
