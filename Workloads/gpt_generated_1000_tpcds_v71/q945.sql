WITH am_returns AS (
    SELECT
        s.s_division_name AS division_name,
        td.t_am_pm AS period,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE td.t_am_pm = 'AM'
      AND c.c_birth_month = 6
    GROUP BY s.s_division_name, td.t_am_pm
),
pm_returns AS (
    SELECT
        s.s_division_name AS division_name,
        td.t_am_pm AS period,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE td.t_am_pm = 'PM'
      AND c.c_birth_month = 12
    GROUP BY s.s_division_name, td.t_am_pm
)
SELECT division_name, period, return_cnt, total_return_amount
FROM am_returns
UNION ALL
SELECT division_name, period, return_cnt, total_return_amount
FROM pm_returns
ORDER BY division_name, period
LIMIT 100
