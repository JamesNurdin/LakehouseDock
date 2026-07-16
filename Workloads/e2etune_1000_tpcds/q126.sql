WITH income_stats AS (
    SELECT w.w_state,
           COUNT(*) AS total_warehouses,
           COUNT(DISTINCT ib.ib_income_band_sk) AS distinct_income_bands,
           SUM(CASE WHEN ib.ib_upper_bound > 30000 THEN 1 ELSE 0 END) AS high_income_band_cnt
    FROM warehouse w
    CROSS JOIN income_band ib
    WHERE w.w_country = 'United States'
    GROUP BY w.w_state
),
reason_stats AS (
    SELECT w.w_state,
           COUNT(*) AS total_records,
           SUM(CASE WHEN r.r_reason_desc LIKE '%damaged%' THEN 1 ELSE 0 END) AS damaged_cnt,
           SUM(CASE WHEN r.r_reason_desc LIKE '%missing%' THEN 1 ELSE 0 END) AS missing_cnt
    FROM warehouse w
    CROSS JOIN reason r
    WHERE r.r_reason_desc IS NOT NULL
    GROUP BY w.w_state
),
time_stats AS (
    SELECT w.w_state,
           COUNT(*) AS time_records,
           AVG(t.t_hour) AS avg_hour,
           COUNT(CASE WHEN t.t_shift = 'Evening' THEN 1 END) AS evening_cnt
    FROM warehouse w
    CROSS JOIN time_dim t
    GROUP BY w.w_state
)
SELECT i.w_state,
       i.total_warehouses,
       i.distinct_income_bands,
       i.high_income_band_cnt,
       r.damaged_cnt,
       r.missing_cnt,
       t.avg_hour,
       t.evening_cnt,
       (i.high_income_band_cnt * 0.5 + r.damaged_cnt * 0.3 + t.evening_cnt * 0.2) AS composite_score,
       RANK() OVER (ORDER BY (i.high_income_band_cnt * 0.5 + r.damaged_cnt * 0.3 + t.evening_cnt * 0.2) DESC) AS state_rank
FROM income_stats i
JOIN reason_stats r ON i.w_state = r.w_state
JOIN time_stats t ON i.w_state = t.w_state
WHERE i.total_warehouses > 5
ORDER BY composite_score DESC
LIMIT 10
