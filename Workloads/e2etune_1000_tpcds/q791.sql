SELECT
    cd_refunded.cd_education_status AS education_status,
    cd_returning.cd_gender AS gender,
    r.r_reason_desc AS reason_desc,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    ROUND(SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt_inc_tax), 0), 4) AS loss_to_return_ratio
FROM web_returns wr
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE cd_refunded.cd_credit_rating = 'Good'
  AND cd_returning.cd_gender = 'F'
  AND cd_refunded.cd_education_status IN ('College', '4 yr Degree')
  AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450200
GROUP BY cd_refunded.cd_education_status, cd_returning.cd_gender, r.r_reason_desc
HAVING SUM(wr.wr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 20
