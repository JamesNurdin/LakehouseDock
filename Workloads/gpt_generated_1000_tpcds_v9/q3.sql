SELECT
    c.c_customer_id,
    c.c_birth_year,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(*) AS return_count
FROM store_returns sr
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1966
  AND sr.sr_return_amt > 400
GROUP BY c.c_customer_id, c.c_birth_year
LIMIT 100
