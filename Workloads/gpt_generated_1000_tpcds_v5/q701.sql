SELECT
  c.c_customer_id,
  c.c_last_name,
  SUM(wr.wr_return_amt) AS total_return_amt,
  COUNT(*) AS return_cnt
FROM web_returns wr
JOIN customer c
  ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE c.c_last_review_date = 2452508
  AND wr.wr_return_tax > 10
  AND wr.wr_web_page_sk = 2413
GROUP BY c.c_customer_id, c.c_last_name
LIMIT 100
