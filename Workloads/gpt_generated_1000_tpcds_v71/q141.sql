SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(*) AS return_cnt
FROM tpcds.web_returns wr
JOIN tpcds.customer c
  ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE c.c_birth_day = 16
  AND wr.wr_return_ship_cost > 500
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
