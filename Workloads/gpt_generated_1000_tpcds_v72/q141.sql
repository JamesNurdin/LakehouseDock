SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sr.sr_return_amt,
    sr.sr_return_quantity
FROM tpcds.customer AS c
JOIN tpcds.store_returns AS sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE sr.sr_return_amt > 100.00
  AND c.c_birth_year = 1963
ORDER BY sr.sr_return_amt DESC
LIMIT 100
