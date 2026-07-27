SELECT
  c.c_customer_id,
  c.c_first_name,
  wr.wr_return_amt_inc_tax,
  wr.wr_return_quantity
FROM tpcds.web_returns AS wr
INNER JOIN tpcds.customer AS c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE wr.wr_return_amt_inc_tax > 500.00
  AND c.c_birth_month = 9
ORDER BY wr.wr_return_amt_inc_tax DESC
LIMIT 100
