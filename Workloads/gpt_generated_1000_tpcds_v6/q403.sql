WITH holiday_returns AS (
    SELECT
        d.d_year,
        'Y' AS holiday_flag,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(sr.sr_return_quantity) AS avg_quantity,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
      AND d.d_week_seq IN (5, 17)
      AND sr.sr_return_quantity > 30
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year
),
nonholiday_returns AS (
    SELECT
        d.d_year,
        'N' AS holiday_flag,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
        AVG(sr.sr_return_quantity) AS avg_quantity,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
      AND d.d_week_seq NOT IN (5, 17)
      AND sr.sr_return_quantity <= 30
      AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year
)
SELECT
    holiday_returns.d_year,
    holiday_returns.holiday_flag,
    holiday_returns.total_return_inc_tax,
    holiday_returns.avg_quantity,
    holiday_returns.return_cnt
FROM holiday_returns
UNION ALL
SELECT
    nonholiday_returns.d_year,
    nonholiday_returns.holiday_flag,
    nonholiday_returns.total_return_inc_tax,
    nonholiday_returns.avg_quantity,
    nonholiday_returns.return_cnt
FROM nonholiday_returns
ORDER BY d_year, holiday_flag, total_return_inc_tax DESC
