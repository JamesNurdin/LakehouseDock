WITH holiday_returns AS (
    SELECT
        d.d_year,
        'Holiday' AS period_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_following_holiday = 'Y'
      AND d.d_dow IN (5, 6)               -- weekend days before a holiday
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year
),
weekday_returns AS (
    SELECT
        d.d_year,
        'Weekday' AS period_type,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_ship_cost) AS total_ship_cost,
        AVG(wr.wr_return_quantity) AS avg_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_following_holiday = 'N'
      AND d.d_dow BETWEEN 1 AND 5        -- regular weekdays
      AND d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year
)
SELECT
    d_year,
    period_type,
    return_cnt,
    total_return_amt,
    total_ship_cost,
    avg_return_qty
FROM holiday_returns
UNION ALL
SELECT
    d_year,
    period_type,
    return_cnt,
    total_return_amt,
    total_ship_cost,
    avg_return_qty
FROM weekday_returns
ORDER BY d_year, period_type
LIMIT 100
