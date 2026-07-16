SELECT
    s.s_state,
    t.t_shift,
    COUNT(DISTINCT s.s_store_id) AS store_cnt,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(s.s_number_employees) AS avg_employees,
    RANK() OVER (PARTITION BY t.t_shift ORDER BY SUM(s.s_floor_space) DESC) AS state_rank
FROM store s
JOIN (
    SELECT DISTINCT t_shift
    FROM time_dim
) t ON true
WHERE s.s_closed_date_sk IS NULL
  AND s.s_rec_end_date > CURRENT_DATE
  AND s.s_number_employees > 0
GROUP BY s.s_state, t.t_shift
HAVING SUM(s.s_floor_space) > 50000
ORDER BY t.t_shift, state_rank
LIMIT 100
