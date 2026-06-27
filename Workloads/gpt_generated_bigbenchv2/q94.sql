WITH sales_union AS (
    SELECT ss.ss_item_id AS item_id,
           ss.ss_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT ws.ws_item_id AS item_id,
           ws.ws_quantity AS quantity,
           i.i_price AS price,
           i.i_category_id,
           i.i_category_name
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),

sales_by_category AS (
    SELECT i_category_id,
           i_category_name,
           SUM(quantity) AS total_qty,
           SUM(quantity * price) AS total_rev
    FROM sales_union
    GROUP BY i_category_id, i_category_name
),

rating_by_category AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_category_rating,
           COUNT(*) AS total_reviews
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)

SELECT s.i_category_id,
       s.i_category_name,
       s.total_qty,
       s.total_rev,
       r.avg_category_rating,
       r.total_reviews
FROM sales_by_category s
LEFT JOIN rating_by_category r
  ON s.i_category_id = r.i_category_id
 AND s.i_category_name = r.i_category_name
ORDER BY s.total_rev DESC
