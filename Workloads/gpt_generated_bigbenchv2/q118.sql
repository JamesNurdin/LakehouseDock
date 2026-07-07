WITH all_sales AS (
  SELECT ss_item_id AS item_id, ss_quantity AS quantity
  FROM store_sales
  UNION ALL
  SELECT ws_item_id AS item_id, ws_quantity AS quantity
  FROM web_sales
),
item_sales AS (
  SELECT
    i.i_item_id,
    i.i_category,
    i.i_category_id,
    SUM(COALESCE(s.quantity, 0)) AS total_quantity
  FROM items i
  LEFT JOIN all_sales s ON s.item_id = i.i_item_id
  GROUP BY i.i_item_id, i.i_category, i.i_category_id
),
item_sentiment AS (
  SELECT
    i.i_item_id,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_item_id
)
SELECT
  i_sales.i_category,
  i_sales.i_category_id,
  SUM(i_sales.total_quantity) AS category_total_quantity,
  AVG(i_sent.avg_sentiment) AS category_avg_sentiment,
  SUM(i_sent.review_count) AS category_review_count
FROM item_sales i_sales
LEFT JOIN item_sentiment i_sent ON i_sent.i_item_id = i_sales.i_item_id
GROUP BY i_sales.i_category, i_sales.i_category_id
ORDER BY category_total_quantity DESC
LIMIT 10
