WITH shift_returns AS (
    SELECT
        td.t_shift,
        td.t_meal_time,
        sr.sr_return_time_sk,
        sr.sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY td.t_shift ORDER BY sr.sr_return_time_sk) AS rn,
        LAG(sr.sr_return_amt) OVER (PARTITION BY td.t_shift ORDER BY sr.sr_return_time_sk) AS prev_return_amt
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
)
SELECT
    t_shift,
    t_meal_time,
    COUNT(*) AS return_count,
    AVG(sr_return_amt) AS avg_return_amt,
    SUM(CASE WHEN prev_return_amt IS NOT NULL AND sr_return_amt > prev_return_amt THEN 1 ELSE 0 END) AS increased_vs_prev,
    SUM(CASE WHEN prev_return_amt IS NOT NULL AND sr_return_amt < prev_return_amt THEN 1 ELSE 0 END) AS decreased_vs_prev
FROM shift_returns
GROUP BY t_shift, t_meal_time
ORDER BY t_shift, t_meal_time
