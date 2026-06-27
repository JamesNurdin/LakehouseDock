WITH item_review_stats AS (
    SELECT pr_item_id AS item_id,
           AVG(pr_rating) AS avg_rating,
           COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       SUM(ss.ss_quantity) AS total_quantity,
       COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
       SUM(ss.ss_quantity * i.i_price) AS total_revenue,
       CASE
           WHEN SUM(ss.ss_quantity) > 0 THEN
                SUM(COALESCE(ir.avg_rating, 0) * ss.ss_quantity) / SUM(ss.ss_quantity)
           ELSE NULL
       END AS weighted_avg_rating,
       SUM(COALESCE(ir.review_count, 0)) AS total_review_count
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_review_stats ir ON i.i_item_id = ir.item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_quantity DESC
