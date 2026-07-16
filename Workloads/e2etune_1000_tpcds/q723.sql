WITH filtered_returns AS (
  SELECT
    sr.sr_return_amt,
    sr.sr_net_loss,
    sr.sr_return_quantity,
    sr.sr_returned_date_sk,
    cd.cd_credit_rating,
    cd.cd_education_status,
    cd.cd_dep_count,
    cd.cd_purchase_estimate
  FROM store_returns sr
  JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
    AND cd.cd_education_status IN ('College', '4 yr Degree')
    AND cd.cd_dep_count >= 1
    AND sr.sr_returned_date_sk BETWEEN 20210101 AND 20211231
)
SELECT
  cd_credit_rating,
  cd_education_status,
  SUM(sr_return_amt) AS total_return_amt,
  SUM(sr_net_loss) AS total_net_loss,
  COUNT(*) AS num_returns,
  AVG(sr_return_quantity) AS avg_return_qty,
  SUM(sr_return_amt) / SUM(SUM(sr_return_amt)) OVER () AS pct_of_total_return,
  RANK() OVER (ORDER BY SUM(sr_return_amt) DESC) AS return_rank
FROM filtered_returns
GROUP BY cd_credit_rating, cd_education_status
HAVING SUM(sr_return_amt) > 20000
ORDER BY total_return_amt DESC
LIMIT 10
