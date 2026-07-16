WITH band_reason_agg AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS total_rows,
        COUNT(DISTINCT ib.ib_income_band_sk) AS distinct_band_count,
        AVG(ib.ib_upper_bound) AS avg_upper_bound,
        SUM(ib.ib_upper_bound - ib.ib_lower_bound) AS total_income_range
    FROM income_band ib
    JOIN reason r ON true
    WHERE ib.ib_upper_bound >= 20000
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY r.r_reason_desc
    HAVING COUNT(*) > 5
)
SELECT
    rra.r_reason_desc,
    rra.total_rows,
    rra.distinct_band_count,
    rra.avg_upper_bound,
    rra.total_income_range,
    RANK() OVER (ORDER BY rra.avg_upper_bound DESC) AS avg_upper_rank
FROM band_reason_agg rra
ORDER BY avg_upper_rank
LIMIT 5
