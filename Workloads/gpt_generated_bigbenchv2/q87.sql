WITH combined_sales AS (
   SELECT ss_item_id AS item_id, ss_quantity AS quantity
   FROM store_sales
   UNION ALL
   SELECT ws_item_id AS item_id, ws_quantity AS quantity
   FROM web_sales
),
sales_agg AS (
   SELECT item_id, SUM(quantity) AS total_quantity
   FROM combined_sales
   GROUP BY item_id
),
review_stats AS (
   SELECT i.i_item_id,
          COUNT(pr.pr_review_id) AS review_count,
          AVG(pr.pr_sentiment) AS avg_sentiment
   FROM items i
   LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       COALESCE(sa.total_quantity, 0) AS total_quantity,
       rs.review_count,
       rs.avg_sentiment
FROM items i
LEFT JOIN sales_agg sa ON sa.item_id = i.i_item_id
LEFT JOIN review_stats rs ON rs.i_item_id = i.i_item_id
WHERE COALESCE(sa.total_quantity, 0) > 0
ORDER BY total_quantity DESC
LIMIT 10
