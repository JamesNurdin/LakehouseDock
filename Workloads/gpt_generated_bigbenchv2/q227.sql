WITH store_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         SUM(ss.ss_quantity) AS total_store_quantity,
         SUM(ss.ss_quantity * i.i_price) AS total_store_sales,
         COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         SUM(ws.ws_quantity) AS total_web_quantity,
         SUM(ws.ws_quantity * i.i_price) AS total_web_sales,
         COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_category_id, i.i_category
)
SELECT COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS category_id,
       COALESCE(s.i_category, w.i_category, r.i_category) AS category_name,
       COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0) AS total_quantity,
       COALESCE(s.total_store_sales, 0) + COALESCE(w.total_web_sales, 0) AS total_sales,
       COALESCE(s.distinct_store_customers, 0) + COALESCE(w.distinct_web_customers, 0) AS distinct_customers,
       r.avg_sentiment,
       COALESCE(r.review_count, 0) AS review_count
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w ON s.i_category_id = w.i_category_id
FULL OUTER JOIN reviews_agg r ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
ORDER BY total_sales DESC
LIMIT 10
