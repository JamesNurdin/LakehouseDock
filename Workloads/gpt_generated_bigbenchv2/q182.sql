WITH sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         SUM(s.quantity) AS total_quantity_sold
  FROM (
    SELECT ss.ss_item_id AS item_id, ss.ss_quantity AS quantity
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_item_id AS item_id, ws.ws_quantity AS quantity
    FROM web_sales ws
  ) s
  JOIN items i ON s.item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
),
review_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         COUNT(pr.pr_review_id) AS review_count,
         AVG(pr.pr_sentiment) AS avg_sentiment
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
)
SELECT
  s.i_category_id,
  s.i_category,
  s.total_quantity_sold,
  COALESCE(r.review_count, 0) AS review_count,
  r.avg_sentiment
FROM sales_agg s
LEFT JOIN review_agg r
  ON s.i_category_id = r.i_category_id
ORDER BY s.total_quantity_sold DESC
