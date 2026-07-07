WITH item_sentiment AS (
    SELECT i.i_item_id,
           AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i
      ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT s.s_store_id,
       s.s_store_name,
       SUM(ss.ss_quantity * i.i_price) AS total_revenue,
       AVG(COALESCE(its.avg_sentiment, 0)) AS avg_item_sentiment
FROM store_sales ss
JOIN stores s
  ON ss.ss_store_id = s.s_store_id
JOIN items i
  ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment its
  ON i.i_item_id = its.i_item_id
GROUP BY s.s_store_id, s.s_store_name
ORDER BY total_revenue DESC
LIMIT 10
