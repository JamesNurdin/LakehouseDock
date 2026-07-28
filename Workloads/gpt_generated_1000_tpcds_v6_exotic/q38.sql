WITH sales_agg AS (
  SELECT
    s.s_store_id,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(ss.ss_ext_tax) AS total_tax,
    COUNT(*) AS sales_txn
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_start_date_sk = d.d_date_sk
          AND p.p_channel_catalog = 'N'
    )
  GROUP BY GROUPING SETS ((s.s_store_id, d.d_year), (s.s_store_id), ())
),
returns_agg AS (
  SELECT
    s.s_store_id,
    d.d_year,
    SUM(sr.sr_refunded_cash) AS total_refunded,
    SUM(sr.sr_return_ship_cost) AS total_return_ship,
    COUNT(*) AS return_txn
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND sr.sr_net_loss > 0
  GROUP BY ROLLUP (s.s_store_id, d.d_year)
)
SELECT
  s_store_id,
  d_year,
  metric,
  amount,
  tax,
  txn_count
FROM (
  SELECT
    s_store_id,
    d_year,
    'sales'   AS metric,
    total_sales AS amount,
    total_tax   AS tax,
    sales_txn   AS txn_count
  FROM sales_agg

  UNION ALL

  SELECT
    s_store_id,
    d_year,
    'returns' AS metric,
    total_refunded   AS amount,
    total_return_ship AS tax,
    return_txn       AS txn_count
  FROM returns_agg
) combined
ORDER BY s_store_id, d_year, metric
