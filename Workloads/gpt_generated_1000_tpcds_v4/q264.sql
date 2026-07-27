SELECT
  c.c_customer_id,
  c.c_birth_month,
  SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns AS wr
JOIN customer AS c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_birth_month = 5
  AND wr.wr_fee > 20.00
GROUP BY c.c_customer_id, c.c_birth_month
ORDER BY total_return_amount DESC
LIMIT 100
