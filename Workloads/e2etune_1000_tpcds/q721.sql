SELECT
    rd.cd_gender AS returning_gender,
    fd.cd_gender AS refunded_gender,
    rd.cd_marital_status AS returning_marital_status,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_amt_inc_tax) / NULLIF(COUNT(*), 0) AS avg_return_amount_per_return,
    RANK() OVER (PARTITION BY rd.cd_gender ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank_by_returning_gender
FROM web_returns wr
JOIN customer_demographics rd ON wr.wr_returning_cdemo_sk = rd.cd_demo_sk
JOIN customer_demographics fd ON wr.wr_refunded_cdemo_sk = fd.cd_demo_sk
WHERE rd.cd_dep_employed_count >= 1
  AND fd.cd_marital_status = 'M'
  AND wr.wr_returned_date_sk BETWEEN 20200101 AND 20201231
GROUP BY rd.cd_gender, fd.cd_gender, rd.cd_marital_status
HAVING COUNT(*) >= 10
ORDER BY total_net_loss DESC
LIMIT 100
