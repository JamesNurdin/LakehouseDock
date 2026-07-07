WITH sales_by_store_item AS (
  SELECT
    ss.ss_store_id AS store_id,
    ss.ss_item_id AS item_id,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  GROUP BY ss.ss_store_id, ss.ss_item_id
),
review_stats AS (
  SELECT
    pr.pr_item_id AS item_id,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(*) AS review_count
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
),
ranked_sales AS (
  SELECT
    sbs.store_id,
    sbs.item_id,
    sbs.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY sbs.store_id ORDER BY sbs.total_quantity DESC) AS rn
  FROM sales_by_store_item sbs
)
SELECT
  st.s_store_name,
  i.i_name,
  i.i_category,
  rs.total_quantity,
  rv.avg_sentiment,
  i.i_price
FROM ranked_sales rs
JOIN stores st ON st.s_store_id = rs.store_id
JOIN items i ON i.i_item_id = rs.item_id
LEFT JOIN review_stats rv ON rv.item_id = i.i_item_id
WHERE rs.rn = 1
ORDER BY st.s_store_name
