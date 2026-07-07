WITH
  store_sales_agg AS (
    SELECT
      s.s_store_name AS store_name,
      i.i_category AS category,
      ss.ss_quantity AS quantity,
      ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
  ),
  web_sales_agg AS (
    SELECT
      CAST('Online' AS varchar) AS store_name,
      i.i_category AS category,
      ws.ws_quantity AS quantity,
      ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
  ),
  combined_sales AS (
    SELECT store_name, category, quantity, revenue FROM store_sales_agg
    UNION ALL
    SELECT store_name, category, quantity, revenue FROM web_sales_agg
  ),
  review_sentiment AS (
    SELECT
      i.i_category AS category,
      AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
  )
SELECT
  cs.store_name,
  cs.category,
  SUM(cs.quantity) AS total_quantity,
  SUM(cs.revenue) AS total_revenue,
  rs.avg_sentiment
FROM combined_sales cs
LEFT JOIN review_sentiment rs ON cs.category = rs.category
GROUP BY cs.store_name, cs.category, rs.avg_sentiment
ORDER BY cs.store_name, cs.category
