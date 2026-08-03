WITH
  returns AS (
    SELECT
      td.t_shift AS shift,
      hd.hd_vehicle_count AS vehicle_count,
      SUM(cr.cr_return_amount) AS total_amount,
      'return' AS metric_type
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_call_center_sk IN (
      SELECT cc.cc_call_center_sk
      FROM call_center cc
      WHERE cc.cc_state = 'CA'
    )
    GROUP BY td.t_shift, hd.hd_vehicle_count
    HAVING SUM(cr.cr_return_amount) > 1000
  ),
  sales AS (
    SELECT
      td.t_shift AS shift,
      hd.hd_vehicle_count AS vehicle_count,
      SUM(ws.ws_ext_sales_price) AS total_amount,
      'sale' AS metric_type
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_warehouse_sk IN (
      SELECT cc.cc_call_center_sk
      FROM call_center cc
      WHERE cc.cc_state = 'CA'
    )
    GROUP BY td.t_shift, hd.hd_vehicle_count
    HAVING SUM(ws.ws_ext_sales_price) > 1000
  )
SELECT
  shift,
  vehicle_count,
  metric_type,
  total_amount,
  ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS global_rn,
  LAG(total_amount) OVER (PARTITION BY metric_type ORDER BY shift) AS lag_total_amount
FROM (
  SELECT * FROM returns
  UNION ALL
  SELECT * FROM sales
) combined
ORDER BY total_amount DESC
LIMIT 100
