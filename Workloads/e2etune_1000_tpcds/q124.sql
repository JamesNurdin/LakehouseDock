WITH ib_summary AS (
    SELECT
        COUNT(*) AS band_count,
        AVG(ib_upper_bound) AS avg_upper,
        AVG(ib_lower_bound) AS avg_lower,
        MAX(ib_upper_bound) AS max_upper,
        MIN(ib_lower_bound) AS min_lower
    FROM income_band
),
quarter_stats AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        COUNT(*) AS days_in_quarter,
        SUM(CASE WHEN d.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_days,
        ib.band_count,
        ib.avg_upper,
        ib.avg_lower
    FROM date_dim d
    JOIN ib_summary ib ON 1=1
    WHERE d.d_year BETWEEN 2018 AND 2022
      AND d.d_weekend = 'Y'
    GROUP BY d.d_year, d.d_quarter_name, ib.band_count, ib.avg_upper, ib.avg_lower
)
SELECT
    qs.d_year,
    qs.d_quarter_name,
    qs.days_in_quarter,
    qs.weekend_days,
    qs.band_count,
    qs.avg_upper,
    qs.avg_lower,
    RANK() OVER (ORDER BY qs.weekend_days DESC) AS weekend_rank
FROM quarter_stats qs
WHERE qs.days_in_quarter >= 30
ORDER BY qs.d_year DESC, qs.weekend_days DESC
