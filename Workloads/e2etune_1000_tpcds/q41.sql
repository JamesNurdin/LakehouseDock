SELECT
  rc.c_customer_sk,
  rc.c_first_name,
  rc.c_last_name,
  rc.c_birth_month,
  SUM(wr.wr_return_amt) AS total_return_amt,
  SUM(wr.wr_net_loss) AS total_net_loss,
  COUNT(*) AS total_returns,
  AVG(wr.wr_return_quantity) AS avg_return_quantity,
  COUNT(DISTINCT rfc.c_customer_sk) AS distinct_refunded_customers,
  SUM(CASE WHEN wr.wr_refunded_customer_sk <> wr.wr_returning_customer_sk THEN 1 ELSE 0 END) AS cross_customer_refunds,
  RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS return_amt_rank
FROM web_returns wr
JOIN customer rc
  ON wr.wr_returning_customer_sk = rc.c_customer_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
  AND wp.wp_customer_sk = rc.c_customer_sk
LEFT JOIN customer rfc
  ON wr.wr_refunded_customer_sk = rfc.c_customer_sk
WHERE rc.c_birth_month = 12
  AND wr.wr_return_quantity > 1
  AND wp.wp_type = 'product'
GROUP BY rc.c_customer_sk, rc.c_first_name, rc.c_last_name, rc.c_birth_month
HAVING COUNT(*) >= 2
ORDER BY total_return_amt DESC
LIMIT 10
