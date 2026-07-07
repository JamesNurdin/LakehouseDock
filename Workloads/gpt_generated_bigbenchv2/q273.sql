WITH store_sales_agg AS (
  SELECT i.i_item_id,
         SUM(ss.ss_quantity) AS total_store_quantity,
         COUNT(ss.ss_transaction_id) AS store_transactions
  FROM store_sales ss
  JOIN items i ON ss.ss_item_id = i.i_item_id
  JOIN customers c ON ss.ss_customer_id = c.c_customer_id
  GROUP BY i.i_item_id
),
web_sales_agg AS (
  SELECT i.i_item_id,
         SUM(ws.ws_quantity) AS total_web_quantity,
         COUNT(ws.ws_transaction_id) AS web_transactions
  FROM web_sales ws
  JOIN items i ON ws.ws_item_id = i.i_item_id
  JOIN customers c ON ws.ws_customer_id = c.c_customer_id
  GROUP BY i.i_item_id
),
review_agg AS (
  SELECT i.i_item_id,
         AVG(pr.pr_sentiment) AS avg_sentiment,
         COUNT(pr.pr_review_id) AS review_count
  FROM product_reviews pr
  JOIN items i ON pr.pr_item_id = i.i_item_id
  GROUP BY i.i_item_id
)
SELECT i.i_item_id,
       i.i_name,
       i.i_category,
       i.i_price,
       COALESCE(ssa.total_store_quantity, 0) AS total_store_quantity,
       COALESCE(wsa.total_web_quantity, 0) AS total_web_quantity,
       COALESCE(ra.avg_sentiment, 0) AS avg_sentiment,
       COALESCE(ra.review_count, 0) AS review_count,
       (COALESCE(ssa.total_store_quantity, 0) + COALESCE(wsa.total_web_quantity, 0)) AS total_quantity
FROM items i
LEFT JOIN store_sales_agg ssa ON i.i_item_id = ssa.i_item_id
LEFT JOIN web_sales_agg wsa ON i.i_item_id = wsa.i_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.i_item_id
WHERE i.i_category IS NOT NULL
ORDER BY total_quantity DESC
LIMIT 100
