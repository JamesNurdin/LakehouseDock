SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(sr.sr_refunded_cash) AS total_refunded_cash,
  COUNT(*) AS return_count
FROM store_returns AS sr
JOIN customer AS c
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'FIJI'
  AND sr.sr_refunded_cash > 50
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_refunded_cash DESC
LIMIT 100
