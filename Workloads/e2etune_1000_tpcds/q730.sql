WITH date_filtered AS (
    SELECT
        d_date_sk,
        d_date,
        d_month_seq,
        d_fy_year,
        d_qoy,
        d_weekend,
        d_holiday,
        d_dom
    FROM date_dim
    WHERE d_fy_year = 1902
      AND d_qoy = 2
      AND d_weekend = 'Y'
),
time_filtered AS (
    SELECT
        t_time_sk,
        t_shift,
        t_meal_time,
        t_hour
    FROM time_dim
    WHERE t_shift = 'Evening'
      AND t_meal_time = 'Dinner'
)
SELECT
    df.d_month_seq,
    tf.t_shift,
    COUNT(DISTINCT CASE WHEN df.d_holiday = 'Y' THEN df.d_date END) AS weekend_holiday_days,
    AVG(CASE WHEN df.d_holiday = 'Y' THEN df.d_dom END) AS avg_day_of_month_holiday,
    RANK() OVER (
        ORDER BY COUNT(DISTINCT CASE WHEN df.d_holiday = 'Y' THEN df.d_date END) DESC
    ) AS rank_by_days,
    ROW_NUMBER() OVER (
        PARTITION BY tf.t_shift
        ORDER BY COUNT(DISTINCT CASE WHEN df.d_holiday = 'Y' THEN df.d_date END) DESC
    ) AS rn_within_shift
FROM date_filtered df
JOIN time_filtered tf
    ON true
GROUP BY df.d_month_seq, tf.t_shift
HAVING COUNT(DISTINCT CASE WHEN df.d_holiday = 'Y' THEN df.d_date END) > 0
ORDER BY weekend_holiday_days DESC
LIMIT 10
