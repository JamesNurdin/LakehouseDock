WITH sales_agg AS (
   SELECT i.i_category_id AS category_id,
          i.i_category AS category_name,
          SUM(ss.ss_quantity) AS total_quantity
   FROM store_sales ss
   JOIN items i ON ss.ss_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
   UNION ALL
   SELECT i.i_category_id AS category_id,
          i.i_category AS category_name,
          SUM(ws.ws_quantity) AS total_quantity
   FROM web_sales ws
   JOIN items i ON ws.ws_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
),
sales_by_category AS (
   SELECT category_id,
          category_name,
          SUM(total_quantity) AS total_quantity
   FROM sales_agg
   GROUP BY category_id, category_name
),
reviews_by_category AS (
   SELECT i.i_category_id AS category_id,
          i.i_category AS category_name,
          AVG(pr.pr_sentiment) AS avg_sentiment,
          COUNT(*) AS review_count
   FROM product_reviews pr
   JOIN items i ON pr.pr_item_id = i.i_item_id
   GROUP BY i.i_category_id, i.i_category
)
SELECT s.category_id,
       s.category_name,
       s.total_quantity,
       r.avg_sentiment,
       r.review_count
FROM sales_by_category s
LEFT JOIN reviews_by_category r
  ON s.category_id = r.category_id
ORDER BY s.total_quantity DESC
