WITH store_item_sales AS (
  SELECT
    s.s_store_id,
    s.s_store_name AS store_name,
    i.i_category AS category,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
  FROM store_sales ss
  JOIN stores s
    ON ss.ss_store_id = s.s_store_id
  JOIN items i
    ON ss.ss_item_id = i.i_item_id
  GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
category_reviews AS (
  SELECT
    i.i_category AS category,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i
    ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category
)
SELECT
  sis.store_name,
  sis.category,
  sis.total_quantity,
  sis.distinct_customers,
  cr.avg_sentiment,
  cr.review_count
FROM store_item_sales sis
JOIN category_reviews cr
  ON sis.category = cr.category
ORDER BY sis.total_quantity DESC
LIMIT 100
