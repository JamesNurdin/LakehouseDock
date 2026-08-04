WITH daily_aggregates AS (
  SELECT
    d_store.d_date,
    d_store.d_day_name,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_total,
    SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
    COUNT(DISTINCT c_store.c_customer_sk) AS distinct_store_customers,
    COUNT(DISTINCT c_refund.c_customer_sk) AS distinct_refund_customers
  FROM tpcds.store_returns sr
  JOIN tpcds.date_dim d_store
    ON sr.sr_returned_date_sk = d_store.d_date_sk
  JOIN tpcds.time_dim t_store
    ON sr.sr_return_time_sk = t_store.t_time_sk
  JOIN tpcds.customer c_store
    ON sr.sr_customer_sk = c_store.c_customer_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d_store.d_date_sk
  JOIN tpcds.time_dim t_web
    ON wr.wr_returned_time_sk = t_web.t_time_sk
  JOIN tpcds.customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
  WHERE d_store.d_weekend = 'N'
    AND d_store.d_year = 2001
    AND t_store.t_hour BETWEEN 9 AND 17
    AND c_store.c_preferred_cust_flag = 'Y'
    AND sr.sr_return_amt_inc_tax > 0
    AND wr.wr_return_amt_inc_tax > 0
  GROUP BY d_store.d_date, d_store.d_day_name
)
SELECT DISTINCT
  d_date,
  d_day_name,
  store_return_total,
  web_return_total,
  (store_return_total + web_return_total) AS total_return_amount,
  CASE WHEN d_day_name IN ('Saturday', 'Sunday') THEN 'Weekend' ELSE 'Weekday' END AS day_type,
  distinct_store_customers,
  distinct_refund_customers
FROM daily_aggregates
ORDER BY total_return_amount DESC
LIMIT 100
