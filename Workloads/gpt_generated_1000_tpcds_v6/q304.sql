SELECT cd.cd_gender,
       cd.cd_marital_status,
       SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
       COUNT(*) AS return_cnt
FROM web_returns wr
JOIN customer_demographics cd
  ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_purchase_estimate > 3000
  AND wr.wr_return_amt_inc_tax > 100
GROUP BY cd.cd_gender, cd.cd_marital_status
LIMIT 100
