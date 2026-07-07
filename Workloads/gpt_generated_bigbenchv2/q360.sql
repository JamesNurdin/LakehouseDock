WITH store_agg AS (
    SELECT i.i_item_id,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i
      ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT i.i_item_id,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i
      ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT pr.pr_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(sa.store_qty, 0) AS store_quantity,
       COALESCE(wa.web_qty, 0) AS web_quantity,
       COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_quantity,
       ra.avg_sentiment,
       ra.review_count
FROM items i
LEFT JOIN store_agg sa
  ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa
  ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra
  ON i.i_item_id = ra.pr_item_id
WHERE COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) > 0
ORDER BY total_quantity DESC
LIMIT 10
