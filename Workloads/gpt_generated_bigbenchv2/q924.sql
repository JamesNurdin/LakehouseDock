WITH unified_sales AS (
  SELECT ss_transaction_id AS transaction_id,
         ss_customer_id AS customer_id,
         ss_item_id AS item_id,
         ss_quantity AS quantity,
         ss_ts AS ts,
         'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT ws_transaction_id AS transaction_id,
         ws_customer_id AS customer_id,
         ws_item_id AS item_id,
         ws_quantity AS quantity,
         ws_ts AS ts,
         'web' AS channel
  FROM web_sales
)
SELECT
  c.c_customer_id,
  c.c_name,
  COUNT(DISTINCT us.transaction_id) AS total_transactions,
  SUM(us.quantity) AS total_quantity,
  SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS store_quantity,
  SUM(CASE WHEN us.channel = 'web'   THEN us.quantity ELSE 0 END) AS web_quantity,
  SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) / NULLIF(SUM(us.quantity), 0) AS store_quantity_ratio,
  SUM(CASE WHEN us.channel = 'web'   THEN us.quantity ELSE 0 END) / NULLIF(SUM(us.quantity), 0) AS web_quantity_ratio,
  COUNT(DISTINCT CASE WHEN us.channel = 'store' THEN us.transaction_id END) AS store_transactions,
  COUNT(DISTINCT CASE WHEN us.channel = 'web'   THEN us.transaction_id END) AS web_transactions,
  AVG(us.quantity) AS avg_quantity_per_transaction,
  AVG(CASE WHEN us.channel = 'store' THEN us.quantity END) AS avg_store_quantity,
  AVG(CASE WHEN us.channel = 'web'   THEN us.quantity END) AS avg_web_quantity
FROM customers c
LEFT JOIN unified_sales us
  ON us.customer_id = c.c_customer_id
GROUP BY c.c_customer_id, c.c_name
HAVING SUM(us.quantity) > 0
ORDER BY total_quantity DESC
LIMIT 10
