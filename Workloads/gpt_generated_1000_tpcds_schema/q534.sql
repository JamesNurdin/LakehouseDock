/*
Goal: Calculate monthly store return totals for the year 1998, identify days with high‑value returns, rank months by total return amount, and keep only months with substantial return volume.
*/
WITH daily_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN sr.sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_returns
    FROM store_returns sr
    FULL OUTER JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
        d.d_date >= DATE '1998-01-01'               -- predicate 1
        AND d.d_date < DATE '1999-01-01'            -- predicate 2
        AND d.d_year = 1998                         -- predicate 3
        AND sr.sr_fee > 10                          -- predicate 4
        AND sr.sr_return_quantity >= 1
        AND sr.sr_return_amt IS NOT NULL
    GROUP BY d.d_year, d.d_month_seq, d.d_date
)
SELECT
    d_year,
    d_month_seq,
    SUM(total_return_amt) AS year_month_return_total,
    AVG(total_return_amt) AS avg_daily_return,
    SUM(high_value_returns) AS total_high_value_days,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(total_return_amt) DESC) AS month_rank_by_return
FROM daily_returns
GROUP BY d_year, d_month_seq
HAVING SUM(total_return_amt) > 5000
ORDER BY d_year, d_month_seq
LIMIT 100
