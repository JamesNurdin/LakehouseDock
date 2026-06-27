WITH store_sales_agg AS (
    SELECT ss_store_id,
           ss_item_id,
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
rating_agg AS (
    SELECT pr_item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT s.s_store_name,
       i.i_category_name,
       SUM(ss.total_quantity) AS store_category_quantity,
       AVG(ra.avg_rating) AS avg_rating,
       SUM(ra.review_count) AS total_reviews
FROM store_sales_agg ss
JOIN items i
  ON ss.ss_item_id = i.i_item_id
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
LEFT JOIN rating_agg ra
  ON ra.pr_item_id = i.i_item_id
GROUP BY s.s_store_name, i.i_category_name
ORDER BY store_category_quantity DESC
LIMIT 20
