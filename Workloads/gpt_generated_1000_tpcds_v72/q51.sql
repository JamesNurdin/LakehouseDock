SELECT
    td.t_shift,
    td.t_hour,
    SUM(wr.wr_return_amt) AS total_return_amt
FROM web_returns wr
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_shift = 'first'
  AND wr.wr_refunded_cash > 100
GROUP BY td.t_shift, td.t_hour
ORDER BY td.t_hour
