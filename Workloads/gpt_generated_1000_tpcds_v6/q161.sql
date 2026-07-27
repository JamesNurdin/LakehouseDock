SELECT
  d.d_date,
  d.d_day_name,
  SUM(wr.wr_return_amt) AS total_return_amt
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_following_holiday = 'N'
  AND d.d_year = 2001
GROUP BY d.d_date, d.d_day_name
ORDER BY total_return_amt DESC
