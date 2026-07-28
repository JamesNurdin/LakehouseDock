SELECT
    c.c_customer_id,
    c.c_last_name,
    c.c_birth_country,
    wr.wr_return_amt,
    wr.wr_fee
FROM tpcds.customer AS c
JOIN tpcds.web_returns AS wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_birth_country = 'CAMBODIA'
  AND wr.wr_fee > 20
ORDER BY wr.wr_return_amt DESC
LIMIT 100
