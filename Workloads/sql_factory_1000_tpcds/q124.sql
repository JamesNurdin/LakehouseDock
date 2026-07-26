WITH dept_monthly AS (
    SELECT
        cp.cp_department,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS monthly_return_amt,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON d.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    GROUP BY cp.cp_department, d.d_year, d.d_month_seq
)
SELECT
    cp_department,
    d_year,
    d_month_seq,
    monthly_return_amt,
    return_cnt,
    return_level,
    ROUND(AVG(monthly_return_amt) OVER (PARTITION BY cp_department ORDER BY d_year, d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m,
    RANK() OVER (PARTITION BY cp_department ORDER BY monthly_return_amt DESC) AS dept_month_rank
FROM dept_monthly
ORDER BY cp_department, d_year, d_month_seq
