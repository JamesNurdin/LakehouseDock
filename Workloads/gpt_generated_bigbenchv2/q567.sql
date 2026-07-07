WITH store_qty AS (
    SELECT ss_item_id AS item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT ws_item_id AS item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
total_qty AS (
    SELECT COALESCE(s.item_id, w.item_id) AS item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_qty s
    FULL OUTER JOIN web_qty w
      ON s.item_id = w.item_id
),
review_agg AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       ra.avg_sentiment,
       ra.review_count,
       tq.total_quantity
FROM items i
JOIN review_agg ra
  ON i.i_item_id = ra.item_id
LEFT JOIN total_qty tq
  ON i.i_item_id = tq.item_id
ORDER BY ra.avg_sentiment DESC, tq.total_quantity DESC
LIMIT 5
