WITH daily_losses AS (
  SELECT 
    cc.cc_call_center_id,
    cc.cc_name,
    d.d_date,
    SUM(cr.cr_net_loss) AS daily_net_loss
  FROM catalog_returns cr
  INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  INNER JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY cc.cc_call_center_id, cc.cc_name, d.d_date
)
SELECT 
  cc_call_center_id,
  cc_name,
  d_date,
  daily_net_loss,
  LAG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date) AS prev_day_net_loss,
  (daily_net_loss - LAG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date)) AS net_loss_change,
  AVG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day,
  CASE 
    WHEN daily_net_loss > COALESCE(LAG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date), 0) THEN 'Increase'
    WHEN daily_net_loss < COALESCE(LAG(daily_net_loss) OVER (PARTITION BY cc_call_center_id ORDER BY d_date), 0) THEN 'Decrease'
    ELSE 'No Change'
  END AS change_indicator,
  RANK() OVER (PARTITION BY cc_call_center_id ORDER BY daily_net_loss DESC) AS loss_rank
FROM daily_losses
WHERE d_date >= DATE '2022-01-01'
ORDER BY cc_call_center_id, d_date
LIMIT 100
