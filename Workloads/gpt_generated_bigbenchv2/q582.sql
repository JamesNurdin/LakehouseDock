WITH item_total_sales AS (
  SELECT i_item_id, SUM(quantity) AS total_qty
  FROM (
    SELECT ss_item_id AS i_item_id, ss_quantity AS quantity FROM store_sales
    UNION ALL
    SELECT ws_item_id AS i_item_id, ws_quantity AS quantity FROM web_sales
  ) s
  GROUP BY i_item_id
),
item_sentiment AS (
  SELECT pr_item_id AS i_item_id, AVG(pr_sentiment) AS avg_sentiment
  FROM product_reviews
  GROUP BY pr_item_id
)
SELECT
  i.i_category AS category,
  SUM(its.total_qty) AS total_quantity,
  AVG(isent.avg_sentiment) AS avg_sentiment
FROM item_total_sales its
JOIN items i ON its.i_item_id = i.i_item_id
LEFT JOIN item_sentiment isent ON i.i_item_id = isent.i_item_id
GROUP BY i.i_category
ORDER BY total_quantity DESC
LIMIT 10
