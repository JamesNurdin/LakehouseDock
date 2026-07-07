WITH sales AS (
  SELECT ss.ss_item_id AS item_id, ss.ss_quantity AS quantity, i.i_price AS price
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  UNION ALL
  SELECT ws.ws_item_id AS item_id, ws.ws_quantity AS quantity, i.i_price AS price
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
),

sales_agg AS (
  SELECT s.item_id,
         SUM(s.quantity) AS total_quantity,
         SUM(s.price * s.quantity) AS total_revenue
  FROM sales s
  GROUP BY s.item_id
),

review_agg AS (
  SELECT pr.pr_item_id AS item_id,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(*) AS review_count
  FROM product_reviews pr
  GROUP BY pr.pr_item_id
)

SELECT i.i_category,
       SUM(sa.total_quantity) AS category_quantity,
       SUM(sa.total_revenue) AS category_revenue,
       AVG(ra.avg_sentiment) AS category_avg_sentiment,
       SUM(ra.review_count) AS total_reviews
FROM sales_agg sa
JOIN items i ON sa.item_id = i.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.item_id
GROUP BY i.i_category
ORDER BY category_revenue DESC
LIMIT 10
