WITH sales AS (
  SELECT ss.ss_item_id AS item_id,
         ss.ss_quantity AS quantity,
         i.i_price AS price,
         i.i_category AS category
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  UNION ALL
  SELECT ws.ws_item_id AS item_id,
         ws.ws_quantity AS quantity,
         i.i_price AS price,
         i.i_category AS category
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
),
review_stats AS (
  SELECT i.i_category AS category,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(*) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category
)
SELECT s.category,
       SUM(s.quantity) AS total_quantity_sold,
       SUM(s.quantity * s.price) AS total_revenue,
       rs.avg_sentiment,
       rs.review_count
FROM sales s
LEFT JOIN review_stats rs ON s.category = rs.category
GROUP BY s.category, rs.avg_sentiment, rs.review_count
ORDER BY total_revenue DESC
LIMIT 10
