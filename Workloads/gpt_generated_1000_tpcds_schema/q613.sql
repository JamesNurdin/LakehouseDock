SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(sr.sr_net_loss) AS total_loss
FROM tpcds.customer c
JOIN tpcds.store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mrs.'
  AND sr.sr_fee > 20
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name
