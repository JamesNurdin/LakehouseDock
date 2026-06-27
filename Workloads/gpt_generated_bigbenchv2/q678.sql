WITH item_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_category_sales AS (
    SELECT s.s_store_id,
           s.s_store_name,
           i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_revenue,
           SUM(COALESCE(ir.avg_rating, 0) * ss.ss_quantity) AS weighted_rating_sum,
           SUM(ss.ss_quantity) AS quantity_for_rating
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_rating ir ON i.i_item_id = ir.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
)
SELECT s_store_id,
       s_store_name,
       i_category_id,
       i_category_name,
       total_quantity,
       total_revenue,
       CASE WHEN quantity_for_rating > 0 THEN weighted_rating_sum / quantity_for_rating ELSE NULL END AS avg_rating_weighted
FROM store_category_sales
ORDER BY total_revenue DESC
LIMIT 50
