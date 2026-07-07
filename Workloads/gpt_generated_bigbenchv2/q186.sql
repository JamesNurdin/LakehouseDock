WITH store_agg AS (
  SELECT
    i.i_category_id,
    i.i_category,
    SUM(ss.ss_quantity) AS store_quantity
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  JOIN customers c ON ss.ss_customer_id = c.c_customer_id
  JOIN stores s ON ss.ss_store_id = s.s_store_id
  GROUP BY i.i_category_id, i.i_category
),
web_agg AS (
  SELECT
    i.i_category_id,
    i.i_category,
    SUM(ws.ws_quantity) AS web_quantity
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  JOIN customers c ON ws.ws_customer_id = c.c_customer_id
  GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
  SELECT
    i.i_category_id,
    i.i_category,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
)
SELECT
  COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) AS category_id,
  COALESCE(sa.i_category, wa.i_category, ra.i_category) AS category_name,
  COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
  ra.avg_sentiment,
  COALESCE(ra.review_count, 0) AS review_count
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.i_category_id = wa.i_category_id
FULL OUTER JOIN review_agg ra ON COALESCE(sa.i_category_id, wa.i_category_id) = ra.i_category_id
ORDER BY total_quantity DESC
LIMIT 5
