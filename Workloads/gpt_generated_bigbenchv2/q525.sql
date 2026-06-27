-- Top 5 stores by total revenue with a weighted average item rating based on store sales
WITH item_ratings AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_sales_agg AS (
    SELECT ss.ss_store_id,
           ss.ss_item_id,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
)
SELECT s.s_store_name,
       SUM(agg.total_quantity) AS store_total_quantity,
       SUM(agg.total_revenue) AS store_total_revenue,
       CASE
           WHEN SUM(agg.total_quantity) > 0 THEN
               SUM(agg.total_quantity * COALESCE(r.avg_rating, 0)) / SUM(agg.total_quantity)
           ELSE NULL
       END AS weighted_avg_rating
FROM store_sales_agg agg
JOIN stores s ON agg.ss_store_id = s.s_store_id
LEFT JOIN item_ratings r ON agg.ss_item_id = r.i_item_id
GROUP BY s.s_store_name
ORDER BY store_total_revenue DESC
LIMIT 5
