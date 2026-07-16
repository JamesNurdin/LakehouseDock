WITH closed_on_holiday AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_country,
        s.s_floor_space,
        s.s_number_employees,
        d.d_fy_year,
        d.d_fy_quarter_seq,
        d.d_date
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
      AND d.d_fy_year BETWEEN 1900 AND 1904
)
SELECT
    cs.s_state,
    cs.s_country,
    cs.d_fy_year,
    cs.d_fy_quarter_seq,
    COUNT(cs.s_store_id) AS closed_store_cnt,
    AVG(cs.s_floor_space) AS avg_floor_space,
    SUM(cs.s_floor_space) AS total_floor_space,
    SUM(cs.s_number_employees) AS total_employees,
    SUM(cs.s_floor_space) / NULLIF(SUM(cs.s_number_employees), 0) AS floor_space_per_employee,
    RANK() OVER (PARTITION BY cs.d_fy_year ORDER BY AVG(cs.s_floor_space) DESC) AS avg_floor_space_rank
FROM closed_on_holiday cs
GROUP BY cs.s_state, cs.s_country, cs.d_fy_year, cs.d_fy_quarter_seq
HAVING COUNT(cs.s_store_id) >= 2
ORDER BY cs.d_fy_year, avg_floor_space_rank
LIMIT 100
