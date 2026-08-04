SELECT
  c.c_birth_country,
  COUNT(*) AS num_returns,
  SUM(sr.sr_return_amt) AS total_return_amount,
  AVG(sr.sr_store_credit) AS avg_store_credit
FROM customer c
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE sr.sr_store_credit > 100
  AND c.c_birth_country IN ('CHILE', 'PHILIPPINES')
GROUP BY c.c_birth_country
ORDER BY total_return_amount DESC
