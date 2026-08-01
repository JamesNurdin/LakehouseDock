SELECT DISTINCT
    td.t_hour,
    td.t_minute,
    td.t_second,
    wr.wr_return_tax,
    wr.wr_return_amt
FROM web_returns wr
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
WHERE wr.wr_return_tax > 30
  AND td.t_second = 16
LIMIT 100
