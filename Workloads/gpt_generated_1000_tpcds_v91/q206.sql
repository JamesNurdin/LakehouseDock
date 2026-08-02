WITH high_vehicle_households AS (
  SELECT hd_demo_sk
  FROM household_demographics
  WHERE hd_vehicle_count > 2
),

store_sales_agg AS (
  SELECT
    ss.ss_hdemo_sk AS hd_demo_sk,
    d.d_year,
    SUM(ss.ss_net_paid) AS amount,
    'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_hdemo_sk IN (SELECT hd_demo_sk FROM high_vehicle_households)
    AND d.d_year = 2001
  GROUP BY ss.ss_hdemo_sk, d.d_year
),

web_returns_agg AS (
  SELECT
    wr.wr_refunded_hdemo_sk AS hd_demo_sk,
    d.d_year,
    -SUM(wr.wr_return_amt) AS amount,
    'web' AS source
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE wr.wr_refunded_hdemo_sk IN (SELECT hd_demo_sk FROM high_vehicle_households)
    AND d.d_year = 2001
    AND wr.wr_reason_sk IN (
      SELECT r.r_reason_sk FROM reason r WHERE r.r_reason_desc LIKE '%defect%'
    )
  GROUP BY wr.wr_refunded_hdemo_sk, d.d_year
)

SELECT DISTINCT
  combined.hd_demo_sk,
  combined.d_year,
  combined.source,
  combined.amount,
  (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM (
  SELECT hd_demo_sk, d_year, source, amount FROM store_sales_agg
  UNION ALL
  SELECT hd_demo_sk, d_year, source, amount FROM web_returns_agg
) AS combined
ORDER BY combined.amount DESC
LIMIT 100
