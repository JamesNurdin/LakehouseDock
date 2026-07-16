SELECT
    s.s_store_id,
    s.s_state,
    d_returned.d_year,
    d_returned.d_current_month,
    t_returned.t_hour,
    COUNT(*) AS num_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) / COUNT(*) AS avg_loss_per_return,
    AVG(DATE_DIFF('day', d_first_ship.d_date, d_returned.d_date)) AS avg_days_since_first_ship,
    AVG(c_returning.c_birth_year) AS avg_returning_birth_year,
    COUNT(DISTINCT c_returning.c_customer_sk) AS distinct_returning_customers,
    RANK() OVER (PARTITION BY d_returned.d_year ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank_by_year
FROM catalog_returns cr
JOIN date_dim d_returned
  ON cr.cr_returned_date_sk = d_returned.d_date_sk
JOIN time_dim t_returned
  ON cr.cr_returned_time_sk = t_returned.t_time_sk
JOIN customer c_refunded
  ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
  ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s
  ON s.s_closed_date_sk = d_returned.d_date_sk
JOIN date_dim d_first_ship
  ON c_refunded.c_first_shipto_date_sk = d_first_ship.d_date_sk
WHERE cr.cr_net_loss > 0
  AND c_refunded.c_preferred_cust_flag = 'Y'
GROUP BY
    s.s_store_id,
    s.s_state,
    d_returned.d_year,
    d_returned.d_current_month,
    t_returned.t_hour
HAVING SUM(cr.cr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
