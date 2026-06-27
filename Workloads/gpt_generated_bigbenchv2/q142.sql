/*
  Analytical query: For each item, compute total quantities sold in stores and on the web,
  total revenue (price * quantity), and review statistics (count and average rating).
  Results are ordered by total revenue descending.
*/
WITH
  store_agg AS (
    SELECT
      ss.ss_item_id AS i_item_id,
      SUM(ss.ss_quantity) AS total_store_qty,
      SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
  ),
  web_agg AS (
    SELECT
      ws.ws_item_id AS i_item_id,
      SUM(ws.ws_quantity) AS total_web_qty,
      SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
  ),
  review_agg AS (
    SELECT
      pr.pr_item_id AS i_item_id,
      COUNT(*) AS review_count,
      AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
  )
SELECT
  i.i_item_id,
  i.i_name,
  i.i_category_name,
  COALESCE(sa.total_store_qty, 0) AS total_store_qty,
  COALESCE(wa.total_web_qty, 0) AS total_web_qty,
  COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
  COALESCE(ra.review_count, 0) AS review_count,
  ra.avg_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
WHERE i.i_price > 0
ORDER BY total_revenue DESC
LIMIT 100
