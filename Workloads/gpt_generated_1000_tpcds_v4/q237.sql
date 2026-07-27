SELECT
  wr.wr_returning_customer_sk,
  SUM(wr.wr_return_amt) AS total_return_amount
FROM tpcds.web_returns AS wr
WHERE wr.wr_returning_customer_sk = 6328036
  AND wr.wr_refunded_cash > 500
GROUP BY wr.wr_returning_customer_sk
LIMIT 100
