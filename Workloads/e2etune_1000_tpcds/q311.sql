WITH catalog AS (
  SELECT r.r_reason_desc AS reason_desc,
         td.t_hour AS hour,
         cr.cr_net_loss AS net_loss,
         cr.cr_return_amt_inc_tax AS return_amt
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450935 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year >= 1970
),
store AS (
  SELECT r.r_reason_desc AS reason_desc,
         td.t_hour AS hour,
         sr.sr_net_loss AS net_loss,
         sr.sr_return_amt_inc_tax AS return_amt
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  WHERE sr.sr_returned_date_sk BETWEEN 2450935 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year >= 1970
),
web AS (
  SELECT r.r_reason_desc AS reason_desc,
         td.t_hour AS hour,
         wr.wr_net_loss AS net_loss,
         wr.wr_return_amt_inc_tax AS return_amt
  FROM web_returns wr
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450935 AND 2451100
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year >= 1970
)
SELECT reason_desc,
       hour,
       SUM(net_loss) AS total_net_loss,
       SUM(return_amt) AS total_return_amount,
       AVG(return_amt) AS avg_return_amount,
       COUNT(*) AS return_count
FROM (
  SELECT * FROM catalog
  UNION ALL
  SELECT * FROM store
  UNION ALL
  SELECT * FROM web
) AS combined
GROUP BY reason_desc, hour
HAVING SUM(return_amt) > 1000
ORDER BY total_net_loss DESC, hour
