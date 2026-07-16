WITH cc_state_agg AS (
    SELECT
        cc_state,
        COUNT(*) AS call_center_cnt,
        SUM(cc_employees) AS total_employees,
        AVG(cc_tax_percentage) AS avg_tax_pct,
        MIN(cc_rec_start_date) AS earliest_start_date,
        MAX(cc_rec_end_date) AS latest_end_date
    FROM call_center
    WHERE cc_rec_start_date >= DATE '2015-01-01'
      AND cc_employees IS NOT NULL
    GROUP BY cc_state
),
time_shift_agg AS (
    SELECT
        t_shift,
        COUNT(*) AS time_rows,
        AVG(t_hour) AS avg_hour,
        SUM(CASE WHEN t_hour BETWEEN 9 AND 17 THEN 1 ELSE 0 END) AS business_hour_rows
    FROM time_dim
    GROUP BY t_shift
)
SELECT
    cs.cc_state,
    cs.call_center_cnt,
    cs.total_employees,
    round(cs.avg_tax_pct, 2) AS avg_tax_pct,
    cs.earliest_start_date,
    cs.latest_end_date,
    ts.t_shift,
    ts.time_rows,
    round(ts.avg_hour, 2) AS avg_hour,
    ts.business_hour_rows,
    rank() OVER (ORDER BY cs.total_employees DESC) AS state_employee_rank
FROM cc_state_agg cs
JOIN time_shift_agg ts ON true
WHERE cs.call_center_cnt >= 5
ORDER BY cs.total_employees DESC, ts.avg_hour ASC
LIMIT 200
