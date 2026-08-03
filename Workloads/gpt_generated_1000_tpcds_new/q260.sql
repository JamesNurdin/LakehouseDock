SELECT
  r.r_reason_desc,
  COUNT(*) AS returns_cnt,
  SUM(w.wr_return_amt) AS total_return_amt
FROM
  web_returns AS w
JOIN
  reason AS r
  ON w.wr_reason_sk = r.r_reason_sk
WHERE
  w.wr_return_amt > 300.00
  AND r.r_reason_desc LIKE '%price%'
GROUP BY
  r.r_reason_desc
ORDER BY
  total_return_amt DESC
LIMIT 10
