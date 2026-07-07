WITH sales_agg AS (
  SELECT i.i_item_id AS item_id,
         SUM(ss.ss_quantity) AS total_quantity,
         SUM(ss.ss_quantity * i.i_price) AS total_revenue
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY i.i_item_id
),
web_sales_agg AS (
  SELECT i.i_item_id AS item_id,
         SUM(ws.ws_quantity) AS total_quantity,
         SUM(ws.ws_quantity * i.i_price) AS total_revenue
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY i.i_item_id
),
combined_sales AS (
  SELECT COALESCE(s.item_id, w.item_id) AS item_id,
         COALESCE(s.total_quantity, 0) + COALESCE(w.total_quantity, 0) AS total_quantity,
         COALESCE(s.total_revenue, 0) + COALESCE(w.total_revenue, 0) AS total_revenue
  FROM sales_agg s
  FULL OUTER JOIN web_sales_agg w ON s.item_id = w.item_id
),
review_agg AS (
  SELECT pr.pr_item_id AS item_id,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(*) AS review_count
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       cs.total_quantity,
       cs.total_revenue,
       ra.avg_sentiment,
       ra.review_count
FROM combined_sales cs
JOIN items i ON cs.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
ORDER BY cs.total_revenue DESC
LIMIT 5
