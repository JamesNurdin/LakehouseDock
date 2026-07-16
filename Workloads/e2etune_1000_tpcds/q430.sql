WITH joined_data AS (
    SELECT
        d.d_fy_year,
        r.r_reason_desc,
        d.d_date,
        d.d_dow,
        CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END AS is_holiday
    FROM date_dim d
    JOIN reason r
        ON (d.d_date_sk % 100) = (r.r_reason_sk % 100)
    WHERE d.d_date BETWEEN DATE '1900-01-01' AND DATE '1904-12-31'
      AND d.d_dow IN (1, 2, 3, 4, 5)
),
agg AS (
    SELECT
        d_fy_year,
        r_reason_desc,
        COUNT(*) AS day_cnt,
        SUM(is_holiday) AS holiday_day_cnt,
        AVG(d_dow) AS avg_day_of_week
    FROM joined_data
    GROUP BY d_fy_year, r_reason_desc
    HAVING COUNT(*) >= 5
)
SELECT
    a.d_fy_year AS fiscal_year,
    a.r_reason_desc AS reason_desc,
    a.day_cnt,
    a.holiday_day_cnt,
    a.avg_day_of_week,
    RANK() OVER (PARTITION BY a.d_fy_year ORDER BY a.day_cnt DESC) AS reason_rank,
    SUM(a.day_cnt) OVER (PARTITION BY a.d_fy_year ORDER BY a.day_cnt DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_day_cnt
FROM agg a
ORDER BY fiscal_year, reason_rank
LIMIT 200
