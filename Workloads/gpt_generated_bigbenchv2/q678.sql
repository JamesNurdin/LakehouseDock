WITH store_sales_data AS (
  SELECT ss.ss_item_id AS item_id,
         i.i_category,
         ss.ss_quantity AS quantity,
         i.i_price AS price
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_data AS (
  SELECT ws.ws_item_id AS item_id,
         i.i_category,
         ws.ws_quantity AS quantity,
         i.i_price AS price
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
  SELECT item_id, i_category, quantity, price FROM store_sales_data
  UNION ALL
  SELECT item_id, i_category, quantity, price FROM web_sales_data
),
sales_agg AS (
  SELECT i_category,
         SUM(quantity) AS total_quantity,
         SUM(quantity * price) AS total_revenue
  FROM combined_sales
  GROUP BY i_category
),
review_agg AS (
  SELECT i.i_category,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(*) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category
)
SELECT s.i_category,
       s.total_quantity,
       s.total_revenue,
       r.avg_sentiment,
       r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category = r.i_category
ORDER BY s.total_revenue DESC
