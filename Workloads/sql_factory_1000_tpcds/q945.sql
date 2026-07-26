WITH quarterly AS (
   SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      d.d_year,
      d.d_quarter_seq,
      SUM(cr.cr_net_loss) AS quarterly_net_loss,
      SUM(cr.cr_return_amount) AS quarterly_return_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_year, d.d_quarter_seq
), with_moving AS (
   SELECT
      cc_call_center_sk,
      cc_name,
      d_year,
      d_quarter_seq,
      quarterly_net_loss,
      AVG(quarterly_net_loss) OVER (PARTITION BY cc_call_center_sk ORDER BY d_year, d_quarter_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_quarter_moving_avg,
      CASE WHEN quarterly_net_loss > 0 THEN 'Profit' ELSE 'Loss' END AS performance_flag
   FROM quarterly
)
SELECT
   cc_call_center_sk,
   cc_name,
   d_year,
   d_quarter_seq,
   quarterly_net_loss,
   three_quarter_moving_avg,
   performance_flag,
   ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY quarterly_net_loss DESC) AS yearly_rank
FROM with_moving
WHERE three_quarter_moving_avg IS NOT NULL
ORDER BY d_year, quarterly_net_loss DESC
LIMIT 20
