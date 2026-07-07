WITH sales_union AS (
  SELECT ss_item_id AS i_item_id, ss_quantity AS quantity
  FROM store_sales
  UNION ALL
  SELECT ws_item_id AS i_item_id, ws_quantity AS quantity
  FROM web_sales
),
item_sales AS (
  SELECT i.i_item_id,
         i.i_name,
         i.i_category,
         COALESCE(SUM(su.quantity), 0) AS total_quantity
  FROM items i
  LEFT JOIN sales_union su ON su.i_item_id = i.i_item_id
  GROUP BY i.i_item_id, i.i_name, i.i_category
),
item_reviews AS (
  SELECT i.i_item_id,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_item_id
)
SELECT s.i_item_id,
       s.i_name,
       s.i_category,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM item_sales s
LEFT JOIN item_reviews r ON r.i_item_id = s.i_item_id
ORDER BY s.total_quantity DESC
LIMIT 10
