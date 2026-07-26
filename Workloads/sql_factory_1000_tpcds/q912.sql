WITH daily_returns AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    dd.d_date,
    cc.cc_call_center_id,
    cc.cc_name,
    sm.sm_ship_mode_id,
    sm.sm_type,
    ROW_NUMBER() OVER (PARTITION BY dd.d_date ORDER BY cr.cr_return_amount DESC) AS rn
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
  d_date,
  cr_order_number,
  cr_return_amount,
  cr_net_loss,
  cr_return_quantity,
  cc_call_center_id,
  cc_name,
  sm_ship_mode_id,
  sm_type,
  CASE
    WHEN cr_return_amount >= 5000 THEN 'Very High'
    WHEN cr_return_amount >= 2000 THEN 'High'
    WHEN cr_return_amount >= 500 THEN 'Medium'
    ELSE 'Low'
  END AS amount_category
FROM daily_returns
WHERE rn <= 5
ORDER BY d_date DESC, cr_return_amount DESC
