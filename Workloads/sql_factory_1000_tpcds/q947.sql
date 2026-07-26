WITH cc_agg AS (
   SELECT
     cc.cc_call_center_sk,
     cc.cc_name,
     cc.cc_manager,
     cc.cc_city,
     cc.cc_state,
     open_date.d_date AS open_date,
     close_date.d_date AS close_date,
     date_diff('day', open_date.d_date, coalesce(close_date.d_date, current_date)) AS days_active,
     SUM(cr.cr_return_quantity) AS total_return_quantity,
     SUM(cr.cr_return_amount) AS total_return_amount,
     SUM(cr.cr_net_loss) AS total_net_loss,
     AVG(cr.cr_return_amount) AS avg_return_amount,
     AVG(t.t_hour) AS avg_return_hour,
     CASE 
        WHEN SUM(cr.cr_net_loss) > 100000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) > 50000 THEN 'Medium'
        ELSE 'Low'
     END AS net_loss_bucket
   FROM catalog_returns cr
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim open_date ON cc.cc_open_date_sk = open_date.d_date_sk
   LEFT JOIN date_dim close_date ON cc.cc_closed_date_sk = close_date.d_date_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_manager, cc.cc_city, cc.cc_state,
            open_date.d_date, close_date.d_date
)
SELECT
   cc_call_center_sk,
   cc_name,
   cc_manager,
   cc_city,
   cc_state,
   open_date,
   close_date,
   days_active,
   total_return_quantity,
   total_return_amount,
   total_net_loss,
   avg_return_amount,
   avg_return_hour,
   net_loss_bucket,
   RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM cc_agg
ORDER BY net_loss_rank
LIMIT 10
