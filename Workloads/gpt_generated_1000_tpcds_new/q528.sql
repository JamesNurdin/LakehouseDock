WITH sales_data AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    'sales' AS metric_type,
    SUM(ss.ss_net_paid) AS total_amount,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'high' ELSE 'normal' END AS category,
    (
      SELECT avg(ss2.ss_ext_discount_amt)
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS related_agg
  FROM store s
  JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk
),
returns_data AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    'returns' AS metric_type,
    SUM(sr.sr_return_amt_inc_tax) AS total_amount,
    COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
    CASE WHEN SUM(sr.sr_return_amt_inc_tax) > 50000 THEN 'high' ELSE 'normal' END AS category,
    (
      SELECT sum(sr2.sr_fee)
      FROM store_returns sr2
      WHERE sr2.sr_store_sk = s.s_store_sk
    ) AS related_agg
  FROM store s
  JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk
)
SELECT
  store_id,
  store_name,
  metric_type,
  total_amount,
  distinct_customers,
  category,
  related_agg
FROM (
  SELECT * FROM sales_data
  UNION ALL
  SELECT * FROM returns_data
) combined
WHERE store_id IN (
  SELECT s_store_id FROM store WHERE s_state = 'TX'
)
ORDER BY total_amount DESC
LIMIT 100
