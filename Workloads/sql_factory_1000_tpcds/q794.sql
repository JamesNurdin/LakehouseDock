WITH daily_loss AS (
   SELECT
      cc.cc_call_center_id,
      cc.cc_name,
      cd.cd_gender,
      cr.cr_returned_date_sk,
      SUM(cr.cr_net_loss) AS daily_net_loss
   FROM catalog_returns cr
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN customer_demographics cd
     ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
   GROUP BY cc.cc_call_center_id, cc.cc_name, cd.cd_gender, cr.cr_returned_date_sk
),
 cumulative AS (
   SELECT
      cc_call_center_id,
      cc_name,
      cd_gender,
      cr_returned_date_sk,
      daily_net_loss,
      SUM(daily_net_loss) OVER (PARTITION BY cc_call_center_id, cd_gender ORDER BY cr_returned_date_sk
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
      LAG(daily_net_loss) OVER (PARTITION BY cc_call_center_id, cd_gender ORDER BY cr_returned_date_sk) AS prev_day_net_loss,
      CASE WHEN daily_net_loss > 0 THEN 'Positive' ELSE 'Negative' END AS daily_loss_indicator
   FROM daily_loss
)
SELECT
   cc_call_center_id,
   cc_name,
   cd_gender,
   cr_returned_date_sk AS return_date_key,
   daily_net_loss,
   cumulative_net_loss,
   prev_day_net_loss,
   daily_loss_indicator,
   CASE
      WHEN prev_day_net_loss IS NOT NULL AND daily_net_loss > prev_day_net_loss THEN 'Increase'
      WHEN prev_day_net_loss IS NOT NULL AND daily_net_loss < prev_day_net_loss THEN 'Decrease'
      ELSE 'No Change'
   END AS day_to_day_trend
FROM cumulative
ORDER BY cc_call_center_id, cd_gender, cr_returned_date_sk
LIMIT 20
