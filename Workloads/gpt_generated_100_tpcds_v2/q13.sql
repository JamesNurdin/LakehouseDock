/*
  Goal: Calculate the average daily return amount per return reason for the year 2000 and identify reasons whose average daily return exceeds $5,000.
*/
WITH daily_reason_returns AS (
    SELECT
        d.d_date AS return_date,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY d.d_date, r.r_reason_desc
)
SELECT
    reason_desc,
    AVG(total_return_amt) AS avg_daily_return_amt,
    COUNT(*) AS days_with_returns
FROM daily_reason_returns
GROUP BY reason_desc
HAVING AVG(total_return_amt) > 5000
ORDER BY avg_daily_return_amt DESC
