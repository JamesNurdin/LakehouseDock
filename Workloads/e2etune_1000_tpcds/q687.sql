WITH yearly_weekends AS (
    SELECT
        sm.sm_type,
        d.d_year,
        COUNT(*) FILTER (WHERE d.d_weekend = 'Y') AS weekend_days,
        COUNT(*) AS total_days
    FROM
        date_dim d
    JOIN
        ship_mode sm
        ON d.d_year = (sm.sm_ship_mode_sk % 5) + 1900
    WHERE
        d.d_current_year = 'Y'
        AND d.d_date >= DATE '1900-01-01'
    GROUP BY
        sm.sm_type,
        d.d_year
)
SELECT
    sm_type,
    AVG(weekend_days) AS avg_weekend_days,
    AVG(total_days) AS avg_total_days,
    RANK() OVER (ORDER BY AVG(weekend_days) DESC) AS weekend_days_rank
FROM
    yearly_weekends
GROUP BY
    sm_type
HAVING
    AVG(total_days) > 0
ORDER BY
    avg_weekend_days DESC
LIMIT 10
