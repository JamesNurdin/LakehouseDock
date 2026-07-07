WITH store_agg AS (
  SELECT
    ss.ss_item_id AS item_id,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(ss.ss_quantity * i.i_price) AS store_revenue
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY ss.ss_item_id
),
web_agg AS (
  SELECT
    ws.ws_item_id AS item_id,
    SUM(ws.ws_quantity) AS web_quantity,
    SUM(ws.ws_quantity * i.i_price) AS web_revenue
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY ws.ws_item_id
),
review_agg AS (
  SELECT
    pr.pr_item_id AS item_id,
    COUNT(*) AS review_count,
    AVG(pr.pr_sentiment) AS avg_sentiment
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
)
SELECT
  i.i_item_id,
  i.i_name,
  i.i_category,
  COALESCE(sa.store_quantity, 0) AS store_quantity,
  COALESCE(wa.web_quantity, 0) AS web_quantity,
  COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
  COALESCE(sa.store_revenue, 0) AS store_revenue,
  COALESCE(wa.web_revenue, 0) AS web_revenue,
  COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
  COALESCE(ra.review_count, 0) AS review_count,
  ra.avg_sentiment
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY total_revenue DESC
LIMIT 10
