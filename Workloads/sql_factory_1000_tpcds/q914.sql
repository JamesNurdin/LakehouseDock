WITH return_agg AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    dd.d_year,
    dd.d_month_seq,
    sm.sm_ship_mode_id,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS total_returns,
    COUNT(*) OVER (PARTITION BY cc.cc_call_center_id, dd.d_year, dd.d_month_seq, sm.sm_ship_mode_id) AS mode_count
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  GROUP BY cc.cc_call_center_id, cc.cc_name, dd.d_year, dd.d_month_seq, sm.sm_ship_mode_id
), ranked_modes AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY cc_call_center_id, d_year, d_month_seq ORDER BY mode_count DESC) AS rn
  FROM return_agg
)
SELECT
  cc_call_center_id,
  cc_name,
  d_year,
  d_month_seq,
  total_return_amount,
  total_net_loss,
  avg_return_amount,
  total_returns,
  sm_ship_mode_id AS top_ship_mode,
  CASE
    WHEN total_net_loss > 10000 THEN 'High'
    WHEN total_net_loss > 5000 THEN 'Medium'
    ELSE 'Low'
  END AS loss_category,
  RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS loss_rank
FROM ranked_modes
WHERE rn = 1
ORDER BY d_year, d_month_seq, loss_rank
