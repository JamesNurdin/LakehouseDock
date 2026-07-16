SELECT
    rc.c_preferred_cust_flag AS returning_customer_flag,
    rc_refunded.c_preferred_cust_flag AS refunded_customer_flag,
    rhd.hd_vehicle_count AS refunded_vehicle_count,
    rhd_returning.hd_income_band_sk AS returning_income_band,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt,
    RANK() OVER (ORDER BY SUM(wr.wr_net_loss) DESC) AS net_loss_rank
FROM web_returns AS wr
JOIN customer AS rc
  ON wr.wr_returning_customer_sk = rc.c_customer_sk
JOIN customer AS rc_refunded
  ON wr.wr_refunded_customer_sk = rc_refunded.c_customer_sk
JOIN household_demographics AS rhd
  ON wr.wr_refunded_hdemo_sk = rhd.hd_demo_sk
JOIN household_demographics AS rhd_returning
  ON wr.wr_returning_hdemo_sk = rhd_returning.hd_demo_sk
WHERE wr.wr_returned_date_sk BETWEEN 2458192 AND 2458195
  AND rc.c_preferred_cust_flag = 'Y'
  AND rc_refunded.c_preferred_cust_flag = 'Y'
GROUP BY rc.c_preferred_cust_flag,
         rc_refunded.c_preferred_cust_flag,
         rhd.hd_vehicle_count,
         rhd_returning.hd_income_band_sk
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
