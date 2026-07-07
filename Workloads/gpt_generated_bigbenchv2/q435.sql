WITH sales_per_item AS (
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
    COALESCE(SUM(s.quantity), 0) AS total_quantity
  FROM items i
  LEFT JOIN sales_per_item s ON s.item_id = i.i_item_id
  GROUP BY i.i_item_id, i.i_category
),
item_review_sentiment AS (
  SELECT
    i.i_item_id,
    i.i_category,
    AVG(pr.pr_sentiment) AS avg_sentiment,
    COALESCE(s.total_quantity, 0) AS total_quantity
  FROM items i
  JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
  LEFT JOIN item_sales s ON s.i_item_id = i.i_item_id
  GROUP BY i.i_item_id, i.i_category, s.total_quantity
)
SELECT
  irs.i_category,
  SUM(irs.avg_sentiment * irs.total_quantity) / NULLIF(SUM(irs.total_quantity), 0) AS avg_weighted_sentiment,
  SUM(irs.total_quantity) AS total_quantity
FROM item_review_sentiment irs
GROUP BY irs.i_category
ORDER BY avg_weighted_sentiment DESC
LIMIT 10
