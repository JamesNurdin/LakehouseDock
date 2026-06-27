/*
  Analytical query: For each item, compute total quantity sold across store and web channels,
  together with average product rating and review count. Results are ordered by total quantity
  sold (descending) and limited to the top 20 items.
*/
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
item_sales AS (
    SELECT i.i_item_id,
           i.i_name,
           i.i_category_name,
           i.i_price,
           COALESCE(s.store_quantity, 0) AS store_quantity,
           COALESCE(w.web_quantity, 0) AS web_quantity,
           COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM items i
    LEFT JOIN store_qty s ON i.i_item_id = s.i_item_id
    LEFT JOIN web_qty w ON i.i_item_id = w.i_item_id
),
item_reviews AS (
    SELECT pr.pr_item_id AS i_item_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT i_sales.i_category_name,
       i_sales.i_name,
       i_sales.i_price,
       i_sales.store_quantity,
       i_sales.web_quantity,
       i_sales.total_quantity,
       COALESCE(i_rev.avg_rating, 0) AS avg_rating,
       COALESCE(i_rev.review_count, 0) AS review_count
FROM item_sales i_sales
LEFT JOIN item_reviews i_rev ON i_sales.i_item_id = i_rev.i_item_id
WHERE i_sales.total_quantity > 0
ORDER BY i_sales.total_quantity DESC
LIMIT 20
