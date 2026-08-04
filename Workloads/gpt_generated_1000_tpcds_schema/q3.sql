SELECT r.r_reason_desc,
       COUNT(*) AS return_cnt,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_return_ship_cost) AS total_ship_cost
FROM tpcds.web_returns AS wr
JOIN tpcds.reason AS r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc = 'Package was damaged'
  AND wr.wr_return_ship_cost > 100
GROUP BY r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 10
