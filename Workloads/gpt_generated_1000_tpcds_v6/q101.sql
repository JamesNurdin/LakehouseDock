SELECT
  r.r_reason_desc,
  SUM(wr.wr_return_amt) AS total_return_amount,
  COUNT(*) AS returns_count
FROM tpcds.web_returns wr
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE wr.wr_returned_date_sk = 2450
  AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
