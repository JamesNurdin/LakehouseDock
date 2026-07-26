WITH hourly AS (
   SELECT
      d.d_date,
      t.t_hour,
      cc.cc_name,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   GROUP BY d.d_date, t.t_hour, cc.cc_name
)
SELECT
   d_date,
   t_hour,
   cc_name,
   total_return_amount,
   total_net_loss,
   CASE WHEN total_return_amount = 0 THEN 0 ELSE total_net_loss / total_return_amount END AS net_loss_ratio,
   DENSE_RANK() OVER (PARTITION BY d_date ORDER BY total_return_amount DESC) AS hour_rank,
   LAG(total_return_amount) OVER (PARTITION BY cc_name ORDER BY d_date) AS prev_day_amount_for_center
FROM hourly
ORDER BY d_date DESC, t_hour
