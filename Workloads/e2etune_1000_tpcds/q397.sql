SELECT
    cd_ret.cd_gender AS returning_gender,
    cd_ret.cd_education_status AS returning_education,
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    cd_ref.cd_gender AS refunded_gender,
    cd_ref.cd_education_status AS refunded_education,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
FROM web_returns wr
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE wr.wr_returned_date_sk BETWEEN 2450844 AND 2451178
  AND cd_ret.cd_gender = 'M'
  AND cd_ref.cd_gender = 'F'
  AND hd_ret.hd_vehicle_count >= 2
  AND hd_ref.hd_vehicle_count >= 1
GROUP BY
    cd_ret.cd_gender,
    cd_ret.cd_education_status,
    hd_ret.hd_vehicle_count,
    cd_ref.cd_gender,
    cd_ref.cd_education_status,
    hd_ref.hd_vehicle_count
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
