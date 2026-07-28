SELECT
  time_dim.t_hour,
  time_dim.t_minute,
  time_dim.t_sub_shift,
  SUM(web_returns.wr_return_amt_inc_tax) AS total_return_amt
FROM web_returns
JOIN time_dim
  ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
WHERE time_dim.t_sub_shift = 'afternoon'
  AND web_returns.wr_return_amt_inc_tax > 100
GROUP BY
  time_dim.t_hour,
  time_dim.t_minute,
  time_dim.t_sub_shift
ORDER BY total_return_amt DESC
LIMIT 100
