WITH store_agg AS (
  SELECT
    ss_customer_id,
    COUNT(ss_transaction_id) AS store_txn_count,
    SUM(ss_quantity) AS store_total_qty,
    MIN(CAST(ss_ts AS timestamp)) AS store_first_ts,
    MAX(CAST(ss_ts AS timestamp)) AS store_last_ts
  FROM store_sales
  GROUP BY ss_customer_id
),
web_agg AS (
  SELECT
    ws_customer_id,
    COUNT(ws_transaction_id) AS web_txn_count,
    SUM(ws_quantity) AS web_total_qty,
    MIN(CAST(ws_ts AS timestamp)) AS web_first_ts,
    MAX(CAST(ws_ts AS timestamp)) AS web_last_ts
  FROM web_sales
  GROUP BY ws_customer_id
)
SELECT
  c.c_customer_id,
  c.c_name,
  COALESCE(s.store_txn_count, 0) AS store_txn_count,
  COALESCE(w.web_txn_count, 0) AS web_txn_count,
  COALESCE(s.store_total_qty, 0) AS store_total_qty,
  COALESCE(w.web_total_qty, 0) AS web_total_qty,
  COALESCE(s.store_total_qty, 0) + COALESCE(w.web_total_qty, 0) AS total_quantity,
  COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0) AS total_txn_count,
  CASE
    WHEN COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0) = 0 THEN NULL
    ELSE (COALESCE(s.store_total_qty, 0) + COALESCE(w.web_total_qty, 0)) / NULLIF(COALESCE(s.store_txn_count, 0) + COALESCE(w.web_txn_count, 0), 0)
  END AS avg_qty_per_txn,
  GREATEST(
    COALESCE(s.store_last_ts, TIMESTAMP '1970-01-01 00:00:00'),
    COALESCE(w.web_last_ts, TIMESTAMP '1970-01-01 00:00:00')
  ) AS last_purchase_ts,
  LEAST(
    COALESCE(s.store_first_ts, TIMESTAMP '9999-12-31 23:59:59'),
    COALESCE(w.web_first_ts, TIMESTAMP '9999-12-31 23:59:59')
  ) AS first_purchase_ts
FROM customers c
LEFT JOIN store_agg s
  ON s.ss_customer_id = c.c_customer_id
LEFT JOIN web_agg w
  ON w.ws_customer_id = c.c_customer_id
ORDER BY total_quantity DESC
LIMIT 20
