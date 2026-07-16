WITH monthly_store_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(CASE WHEN d.d_holiday = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS holiday_return_amount,
        COUNT(*) AS total_returns,
        COUNT(CASE WHEN d.d_holiday = 'Y' THEN 1 END) AS holiday_returns
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY d.d_year, d.d_month_seq, sr.sr_store_sk
)
SELECT
    d_year,
    d_month_seq,
    sr_store_sk,
    total_return_amount,
    holiday_return_amount,
    total_returns,
    holiday_returns,
    (holiday_return_amount / total_return_amount) * 100 AS pct_holiday_return_amount
FROM monthly_store_returns
ORDER BY total_return_amount DESC
LIMIT 10
