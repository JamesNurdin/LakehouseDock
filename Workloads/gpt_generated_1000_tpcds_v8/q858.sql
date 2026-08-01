SELECT
    td.t_hour,
    COUNT(*) AS returns_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_account_credit) AS avg_credit
FROM web_returns wr
JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
WHERE td.t_am_pm = 'PM'
  AND wr.wr_account_credit > 200
GROUP BY td.t_hour
ORDER BY total_return_amt DESC
