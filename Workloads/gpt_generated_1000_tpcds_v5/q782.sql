SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    wr.wr_return_amt,
    wr.wr_return_quantity
FROM tpcds.web_returns wr
JOIN tpcds.customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE wr.wr_return_amt > 100.00
  AND c.c_birth_country = 'KOREA'
ORDER BY wr.wr_return_amt DESC
LIMIT 100
