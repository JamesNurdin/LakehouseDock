WITH store_qty AS (
    SELECT ss_item_id AS i_item_id,
           SUM(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_qty AS (
    SELECT ws_item_id AS i_item_id,
           SUM(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
total_qty AS (
    SELECT COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_qty s
    FULL OUTER JOIN web_qty w
      ON s.i_item_id = w.i_item_id
),
rating_agg AS (
    SELECT pr_item_id AS i_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category_name,
       tq.total_quantity,
       ra.avg_rating,
       ra.review_count,
       (tq.total_quantity * ra.avg_rating) AS weighted_rating
FROM total_qty tq
JOIN items i
  ON i.i_item_id = tq.i_item_id
LEFT JOIN rating_agg ra
  ON ra.i_item_id = i.i_item_id
ORDER BY weighted_rating DESC
LIMIT 10
