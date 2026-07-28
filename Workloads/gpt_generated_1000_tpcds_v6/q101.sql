SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_return_tax) AS total_return_tax
FROM web_returns wr
JOIN customer c
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE wr.wr_refunded_customer_sk = 8372456
  AND c.c_birth_day = 6
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
