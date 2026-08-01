SELECT r.r_reason_desc,
       COUNT(*) AS return_cnt,
       SUM(wr.wr_return_amt) AS total_return_amount,
       AVG(wr.wr_return_amt) AS avg_return_amount
FROM tpcds.web_returns wr
JOIN tpcds.reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc IN ('Package was damaged', 'Parts missing')
  AND wr.wr_return_quantity > 1
GROUP BY r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
