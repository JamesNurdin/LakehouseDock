WITH
  returns AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_vehicle_count,
      'return' AS metric_type,
      SUM(cr.cr_return_amt_inc_tax) AS total_amount
    FROM catalog_returns cr
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amt_inc_tax > 1000
      AND r.r_reason_desc = 'Did not like the warranty'
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
  ),
  sales AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_vehicle_count,
      'sale' AS metric_type,
      SUM(ss.ss_net_paid_inc_tax) AS total_amount
    FROM store_sales ss
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_paid_inc_tax > 1000
      AND ss.ss_quantity > 1
    GROUP BY hd.hd_demo_sk, hd.hd_vehicle_count
  )
SELECT
  hd_demo_sk,
  hd_vehicle_count,
  metric_type,
  total_amount
FROM returns
UNION ALL
SELECT
  hd_demo_sk,
  hd_vehicle_count,
  metric_type,
  total_amount
FROM sales
ORDER BY total_amount DESC
LIMIT 50
