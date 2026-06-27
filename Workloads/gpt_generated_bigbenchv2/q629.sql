WITH store_item_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
store_item_reviews AS (
    SELECT s.s_store_id,
           i.i_category_id,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY s.s_store_id, i.i_category_id
)
SELECT si.s_store_id,
       si.s_store_name,
       si.i_category_id,
       si.i_category_name,
       si.total_quantity,
       si.total_revenue,
       sr.avg_rating,
       sr.review_count
FROM store_item_sales si
LEFT JOIN store_item_reviews sr
  ON si.s_store_id = sr.s_store_id
 AND si.i_category_id = sr.i_category_id
ORDER BY si.total_quantity DESC
LIMIT 100
