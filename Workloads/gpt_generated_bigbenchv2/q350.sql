WITH sales_per_item AS (
  SELECT
    ss.ss_store_id,
    ss.ss_item_id,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count
  FROM store_sales ss
  GROUP BY ss.ss_store_id, ss.ss_item_id
),
review_stats AS (
  SELECT
    pr.pr_item_id,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(*) AS review_count
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
)
SELECT
  s.s_store_name,
  i.i_category,
  SUM(spi.total_quantity) AS total_quantity,
  SUM(spi.transaction_count) AS total_transactions,
  AVG(rs.avg_sentiment) AS avg_sentiment,
  SUM(rs.review_count) AS total_reviews
FROM sales_per_item spi
JOIN items i
  ON spi.ss_item_id = i.i_item_id
JOIN stores s
  ON spi.ss_store_id = s.s_store_id
LEFT JOIN review_stats rs
  ON i.i_item_id = rs.pr_item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY s.s_store_name, i.i_category
