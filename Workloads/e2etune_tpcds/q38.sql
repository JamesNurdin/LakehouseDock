WITH time_stats AS (
    SELECT
        t_shift,
        COUNT(*) AS total_time_rows,
        AVG(t_hour) AS avg_hour,
        SUM(t_time) AS sum_time
    FROM time_dim
    WHERE t_hour BETWEEN 6 AND 22
    GROUP BY t_shift
),
store_state_stats AS (
    SELECT
        s_state,
        COUNT(*) AS store_cnt,
        AVG(s_floor_space) AS avg_floor_space,
        SUM(s_floor_space) AS total_floor_space,
        AVG(s_number_employees) AS avg_employees
    FROM store
    WHERE s_number_employees BETWEEN 200 AND 300
    GROUP BY s_state
)
SELECT
    ss.s_state,
    ss.store_cnt,
    ss.total_floor_space,
    ts.t_shift,
    ts.total_time_rows,
    RANK() OVER (ORDER BY ss.total_floor_space DESC) AS state_floor_space_rank,
    ROW_NUMBER() OVER (PARTITION BY ss.s_state ORDER BY ts.total_time_rows DESC) AS shift_rank_in_state
FROM store_state_stats ss
JOIN time_stats ts
    ON ts.t_shift = CASE
        WHEN ss.s_state IN ('NC','AL') THEN 'Morning'
        WHEN ss.s_state IN ('MN','NE') THEN 'Afternoon'
        ELSE 'Night'
    END
WHERE ss.store_cnt >= 2
ORDER BY ss.total_floor_space DESC, ts.total_time_rows DESC
LIMIT 20
