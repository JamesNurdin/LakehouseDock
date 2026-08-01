SELECT
  c.c_customer_id,
  c.c_last_name,
  wr.wr_order_number,
  wr.wr_return_amt,
  wr.wr_net_loss
FROM tpcds.customer AS c
INNER JOIN tpcds.web_returns AS wr
  ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE c.c_last_review_date = 2452398
  AND wr.wr_refunded_hdemo_sk = 1870
ORDER BY wr.wr_return_amt DESC
LIMIT 100
