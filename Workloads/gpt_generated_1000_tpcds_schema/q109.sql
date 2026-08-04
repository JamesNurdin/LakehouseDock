WITH sales AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    d.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS amount,
    'sales' AS metric_type
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND s.s_state = 'CA'
  GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
returns AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    d.d_year AS year,
    SUM(sr.sr_return_amt) AS amount,
    'returns' AS metric_type
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2020
    AND sr.sr_net_loss > 0
  GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
)
SELECT
  ROW_NUMBER() OVER (ORDER BY amount DESC) AS row_num,
  store_id,
  store_name,
  year,
  metric_type,
  amount
FROM combined
ORDER BY amount DESC
