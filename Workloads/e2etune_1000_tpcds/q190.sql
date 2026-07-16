SELECT
  division_name,
  ship_mode_type,
  gender,
  state,
  num_returns,
  total_return_amount,
  avg_return_quantity,
  total_tax,
  avg_return_amt_inc_tax,
  RANK() OVER (PARTITION BY division_name ORDER BY total_return_amount DESC) AS rank_by_return
FROM (
  SELECT
    cc.cc_division_name AS division_name,
    sm.sm_type AS ship_mode_type,
    cd.cd_gender AS gender,
    w.w_state AS state,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(cr.cr_return_tax) AS total_tax,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
    AND cc.cc_division IN (1, 3, 5)
    AND sm.sm_type IN ('AIR', 'RAIL')
    AND w.w_state IN ('CA', 'TX', 'NY')
  GROUP BY cc.cc_division_name, sm.sm_type, cd.cd_gender, w.w_state
  HAVING SUM(cr.cr_return_amount) > 1000
) t
ORDER BY total_return_amount DESC
LIMIT 20
