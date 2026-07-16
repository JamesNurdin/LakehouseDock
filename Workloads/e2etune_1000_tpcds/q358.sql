WITH agg AS (
  SELECT
    td.t_hour,
    cd_ret.cd_gender,
    cd_ref.cd_marital_status,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
  JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  WHERE td.t_shift = 'Evening'
    AND cd_ret.cd_credit_rating = 'High Risk'
    AND cd_ref.cd_education_status = 'College'
  GROUP BY td.t_hour, cd_ret.cd_gender, cd_ref.cd_marital_status
  HAVING SUM(wr.wr_net_loss) > 1000
)
SELECT
  t_hour,
  cd_gender,
  cd_marital_status,
  num_returns,
  total_net_loss,
  avg_return_amount,
  RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 50
