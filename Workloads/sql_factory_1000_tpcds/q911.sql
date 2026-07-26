WITH daily_cc AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    dd.d_date,
    SUM(cr.cr_return_amount) AS daily_return_amount,
    SUM(cr.cr_net_loss) AS daily_net_loss
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  GROUP BY cc.cc_call_center_id, cc.cc_name, dd.d_date
), running_stats AS (
  SELECT
    cc_call_center_id,
    cc_name,
    d_date,
    daily_return_amount,
    daily_net_loss,
    SUM(daily_return_amount) OVER (PARTITION BY cc_call_center_id ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount,
    AVG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_net_loss_7d
  FROM daily_cc
)
SELECT
  rs.cc_call_center_id,
  rs.cc_name,
  rs.d_date,
  rs.daily_return_amount,
  rs.cumulative_return_amount,
  rs.moving_avg_net_loss_7d,
  CASE
    WHEN od.d_date IS NOT NULL AND rs.d_date >= od.d_date AND (cd.d_date IS NULL OR rs.d_date <= cd.d_date) THEN 'Open'
    WHEN cd.d_date IS NOT NULL AND rs.d_date > cd.d_date THEN 'Closed'
    ELSE 'Future'
  END AS center_status
FROM running_stats rs
LEFT JOIN call_center c ON rs.cc_call_center_id = c.cc_call_center_id
LEFT JOIN date_dim od ON c.cc_open_date_sk = od.d_date_sk
LEFT JOIN date_dim cd ON c.cc_closed_date_sk = cd.d_date_sk
ORDER BY rs.cc_call_center_id, rs.d_date
