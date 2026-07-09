WITH closed_stores AS (
    SELECT
        s.s_state AS state,
        s.s_floor_space AS floor_space,
        d.d_holiday AS holiday,
        d.d_weekend AS weekend
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1902
      AND d.d_fy_quarter_seq = 2
)
SELECT
    state,
    closed_store_cnt,
    total_floor_space,
    avg_floor_space,
    holiday_closures,
    weekend_closures,
    RANK() OVER (ORDER BY closed_store_cnt DESC) AS state_rank
FROM (
    SELECT
        state,
        COUNT(*) AS closed_store_cnt,
        SUM(floor_space) AS total_floor_space,
        AVG(floor_space) AS avg_floor_space,
        SUM(CASE WHEN holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_closures,
        SUM(CASE WHEN weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_closures
    FROM closed_stores
    GROUP BY state
    HAVING COUNT(*) >= 5
) AS agg
ORDER BY closed_store_cnt DESC
LIMIT 10
