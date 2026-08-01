SELECT
  r.r_reason_desc,
  SUM(DISTINCT w.wr_return_amt_inc_tax) AS distinct_total_return
FROM
  web_returns w
JOIN
  reason r
  ON w.wr_reason_sk = r.r_reason_sk
WHERE
  w.wr_return_amt_inc_tax > 500
  AND r.r_reason_desc LIKE '%damaged%'
GROUP BY
  r.r_reason_desc
ORDER BY
  distinct_total_return DESC
LIMIT 100
