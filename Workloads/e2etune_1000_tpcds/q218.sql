SELECT
    t.t_hour AS hour_of_day,
    c_ref.c_birth_month AS refunded_birth_month,
    c_ret.c_birth_month AS returning_birth_month,
    c_ref.c_current_cdemo_sk AS refunded_demo_key,
    c_ret.c_current_cdemo_sk AS returning_demo_key,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax
FROM web_returns wr
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer c_ref
    ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
WHERE t.t_hour BETWEEN 8 AND 20
  AND c_ref.c_birth_month IN (4, 7, 9)
  AND c_ret.c_birth_month IN (5, 10)
  AND c_ref.c_current_cdemo_sk = 980124
  AND c_ret.c_current_cdemo_sk = 819667
GROUP BY
    t.t_hour,
    c_ref.c_birth_month,
    c_ret.c_birth_month,
    c_ref.c_current_cdemo_sk,
    c_ret.c_current_cdemo_sk
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_net_loss DESC, total_return_amount DESC
LIMIT 50
