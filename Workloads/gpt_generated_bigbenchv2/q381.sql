WITH item_avg_rating AS (
    SELECT i.i_item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       SUM(i.i_price * ss.ss_quantity) AS total_revenue,
       SUM(ss.ss_quantity) AS total_quantity,
       SUM(COALESCE(r.avg_rating, 0) * ss.ss_quantity) / SUM(ss.ss_quantity) AS weighted_avg_rating
FROM store_sales ss
JOIN items i
  ON ss.ss_item_id = i.i_item_id
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
LEFT JOIN item_avg_rating r
  ON i.i_item_id = r.i_item_id
GROUP BY s.s_store_id, s.s_store_name
HAVING SUM(ss.ss_quantity) > 1000
ORDER BY total_revenue DESC
LIMIT 5
