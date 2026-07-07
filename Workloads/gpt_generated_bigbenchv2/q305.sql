WITH sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         SUM(ss.ss_quantity) AS store_quantity,
         SUM(ss.ss_quantity * i.i_price) AS store_revenue,
         COUNT(DISTINCT ss.ss_customer_id) AS store_customers
  FROM store_sales ss
  JOIN customers c ON ss.ss_customer_id = c.c_customer_id
  JOIN items i ON ss.ss_item_id = i.i_item_id
  JOIN stores s ON ss.ss_store_id = s.s_store_id
  GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
  SELECT i.i_category_id,
         i.i_category,
         SUM(ws.ws_quantity) AS web_quantity,
         SUM(ws.ws_quantity * i.i_price) AS web_revenue,
         COUNT(DISTINCT ws.ws_customer_id) AS web_customers
  FROM web_sales ws
  JOIN customers c ON ws.ws_customer_id = c.c_customer_id
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
SELECT COALESCE(sales.i_category_id, web.i_category_id, rev.i_category_id) AS category_id,
       COALESCE(sales.i_category, web.i_category, rev.i_category) AS category_name,
       COALESCE(sales.store_quantity, 0) + COALESCE(web.web_quantity, 0) AS total_quantity,
       COALESCE(sales.store_revenue, 0) + COALESCE(web.web_revenue, 0) AS total_revenue,
       COALESCE(sales.store_customers, 0) + COALESCE(web.web_customers, 0) AS total_customers,
       rev.avg_sentiment,
       rev.review_count
FROM sales_agg sales
FULL OUTER JOIN web_sales_agg web ON sales.i_category_id = web.i_category_id
FULL OUTER JOIN reviews_agg rev ON COALESCE(sales.i_category_id, web.i_category_id) = rev.i_category_id
ORDER BY total_revenue DESC
LIMIT 10
