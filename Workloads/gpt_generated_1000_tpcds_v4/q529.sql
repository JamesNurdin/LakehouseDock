WITH daily_returns AS (
    SELECT
        d.d_date AS return_date,
        cp.cp_department AS department,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND t.t_shift = 'first'
      AND wr.wr_return_ship_cost > 100.00
      AND wr.wr_return_quantity >= 1
    GROUP BY d.d_date, cp.cp_department
),
avg_daily AS (
    SELECT
        department,
        AVG(total_return_amt) AS avg_return_amt,
        AVG(total_return_qty) AS avg_return_qty,
        AVG(return_cnt) AS avg_return_cnt
    FROM daily_returns
    GROUP BY department
),
high_dept AS (
    SELECT department, avg_return_amt
    FROM avg_daily
    WHERE avg_return_amt > 500.00
),
low_dept AS (
    SELECT department, avg_return_amt
    FROM avg_daily
    WHERE avg_return_amt <= 500.00
)
SELECT
    department,
    avg_return_amt,
    'high' AS tier
FROM high_dept
UNION ALL
SELECT
    department,
    avg_return_amt,
    'low' AS tier
FROM low_dept
ORDER BY avg_return_amt DESC, department
