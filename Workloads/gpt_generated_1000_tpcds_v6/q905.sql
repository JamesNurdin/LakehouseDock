SELECT
  r.r_reason_desc,
  COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
  SUM(wr.wr_return_amt) AS total_return_amt
FROM
  web_returns wr
JOIN
  reason r
  ON wr.wr_reason_sk = r.r_reason_sk
WHERE
  wr.wr_returned_date_sk IN (2451349, 2450912)
  AND wr.wr_reversed_charge > 20
GROUP BY
  r.r_reason_desc
ORDER BY
  total_return_amt DESC
LIMIT 100
