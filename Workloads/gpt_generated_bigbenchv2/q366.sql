WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
       SUM(ss.ss_quantity) AS total_quantity_sold,
       SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) AS weighted_rating_sum,
       SUM(ss.ss_quantity * COALESCE(ir.avg_rating, 0)) / NULLIF(SUM(ss.ss_quantity), 0) AS weighted_avg_rating
FROM store_sales ss
JOIN stores s ON ss.ss_store_id = s.s_store_id
JOIN customers c ON ss.ss_customer_id = c.c_customer_id
JOIN items i ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_avg_rating ir ON i.i_item_id = ir.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY weighted_avg_rating DESC
LIMIT 10
