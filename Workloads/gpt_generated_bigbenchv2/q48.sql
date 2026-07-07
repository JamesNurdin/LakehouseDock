WITH unified_sales AS (
  SELECT
    ss_transaction_id AS transaction_id,
    ss_customer_id AS customer_id,
    ss_store_id AS store_id,
    ss_item_id AS item_id,
    ss_quantity AS quantity,
    ss_ts AS ts,
    'store' AS channel
  FROM store_sales
  UNION ALL
  SELECT
    ws_transaction_id AS transaction_id,
    ws_customer_id AS customer_id,
    CAST(NULL AS bigint) AS store_id,
    ws_item_id AS item_id,
    ws_quantity AS quantity,
    ws_ts AS ts,
    'web' AS channel
  FROM web_sales
)
SELECT
  c.c_customer_id,
  c.c_name,
  i.i_category,
  SUM(u.quantity) AS total_quantity,
  SUM(u.quantity * i.i_price) AS total_revenue,
  SUM(CASE WHEN u.channel = 'store' THEN u.quantity * i.i_price ELSE 0 END) AS store_revenue,
  SUM(CASE WHEN u.channel = 'web' THEN u.quantity * i.i_price ELSE 0 END) AS web_revenue
FROM unified_sales u
JOIN customers c
  ON u.customer_id = c.c_customer_id
JOIN items i
  ON u.item_id = i.i_item_id
LEFT JOIN stores s
  ON u.store_id = s.s_store_id
GROUP BY
  c.c_customer_id,
  c.c_name,
  i.i_category
ORDER BY total_revenue DESC
LIMIT 10
