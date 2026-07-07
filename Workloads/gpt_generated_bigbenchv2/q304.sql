WITH
  store_agg AS (
    SELECT ss.ss_item_id,
           SUM(ss.ss_quantity) AS total_store_qty
    FROM store_sales ss
    GROUP BY ss.ss_item_id
  ),
  web_agg AS (
    SELECT ws.ws_item_id,
           SUM(ws.ws_quantity) AS total_web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
  ),
  review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
  )
SELECT
  i.i_category_id,
  i.i_category,
  AVG(i.i_price) AS avg_item_price,
  COALESCE(sa.total_store_qty, 0) AS total_store_quantity,
  COALESCE(wa.total_web_qty, 0) AS total_web_quantity,
  COALESCE(ra.avg_sentiment, NULL) AS avg_review_sentiment,
  COALESCE(ra.review_count, 0) AS review_count
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
GROUP BY i.i_category_id,
         i.i_category,
         sa.total_store_qty,
         wa.total_web_qty,
         ra.avg_sentiment,
         ra.review_count
ORDER BY i.i_category_id
