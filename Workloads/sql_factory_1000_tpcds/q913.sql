WITH loss_ratio AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    sm.sm_ship_mode_id,
    sm.sm_type,
    dd.d_fy_year,
    dd.d_fy_quarter_seq,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    CASE
      WHEN SUM(cr.cr_return_amount) = 0 THEN NULL
      ELSE SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount)
    END AS net_loss_ratio
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  GROUP BY cc.cc_call_center_id, cc.cc_name, sm.sm_ship_mode_id, sm.sm_type, dd.d_fy_year, dd.d_fy_quarter_seq
)
SELECT
  cc_call_center_id,
  cc_name,
  sm_ship_mode_id,
  sm_type,
  d_fy_year,
  d_fy_quarter_seq,
  total_net_loss,
  total_return_amount,
  net_loss_ratio,
  CASE
    WHEN net_loss_ratio IS NULL THEN 'Undefined'
    WHEN net_loss_ratio > 0.5 THEN 'Critical'
    WHEN net_loss_ratio > 0.2 THEN 'High'
    WHEN net_loss_ratio > 0.1 THEN 'Medium'
    ELSE 'Low'
  END AS risk_level,
  DENSE_RANK() OVER (PARTITION BY cc_call_center_id, d_fy_year, d_fy_quarter_seq ORDER BY net_loss_ratio DESC) AS ship_mode_rank
FROM loss_ratio
WHERE total_return_amount > 0
ORDER BY cc_call_center_id, d_fy_year, d_fy_quarter_seq, ship_mode_rank
