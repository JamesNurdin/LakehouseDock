SELECT
  c.c_customer_id,
  c.c_birth_country,
  td.t_meal_time,
  COUNT(DISTINCT ss.ss_ticket_number) AS ticket_cnt,
  SUM(sr.sr_net_loss) AS total_net_loss,
  SUM(ss.ss_net_paid) AS total_net_paid,
  AVG(ss.ss_ext_sales_price) AS avg_ext_sales_price
FROM
  tpcds.customer c
  JOIN tpcds.store_sales ss
    ON c.c_customer_sk = ss.ss_customer_sk
  JOIN tpcds.store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND sr.sr_customer_sk = c.c_customer_sk
  JOIN tpcds.time_dim td
    ON sr.sr_return_time_sk = td.t_time_sk
WHERE
  c.c_birth_country = 'UKRAINE'
  AND c.c_preferred_cust_flag = 'Y'
  AND sr.sr_refunded_cash > 1000
  AND td.t_hour BETWEEN 12 AND 14
  AND ss.ss_ext_sales_price > 5000
GROUP BY
  c.c_customer_id,
  c.c_birth_country,
  td.t_meal_time
LIMIT 100
