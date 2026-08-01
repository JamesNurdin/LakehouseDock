SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(sr.sr_return_amt) AS total_return_amount,
  SUM(sr.sr_return_tax) AS total_return_tax,
  SUM(sr.sr_net_loss) AS total_net_loss
FROM tpcds.customer c
JOIN tpcds.store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_day IN (19, 26)
  AND sr.sr_return_amt > 200
  AND sr.sr_return_tax < 5
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
