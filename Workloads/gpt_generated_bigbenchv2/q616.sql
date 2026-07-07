WITH sales_combined AS (
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
category_sales AS (
  SELECT category,
         SUM(quantity) AS total_quantity,
         SUM(quantity * price) AS total_revenue
  FROM sales_combined
  GROUP BY category
),
category_reviews AS (
  SELECT i.i_category AS category,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category
)
SELECT cs.category,
       cs.total_quantity,
       cs.total_revenue,
       cr.avg_sentiment,
       cr.review_count
FROM category_sales cs
LEFT JOIN category_reviews cr ON cs.category = cr.category
ORDER BY cs.total_revenue DESC
LIMIT 10
