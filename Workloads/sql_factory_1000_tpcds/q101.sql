SELECT s.s_store_id,
       s.s_store_name,
       s.s_state,
       s.s_floor_space,
       RANK() OVER (PARTITION BY s.s_state ORDER BY s.s_floor_space DESC) AS floor_space_rank,
       s.s_floor_space - COALESCE(LAG(s.s_floor_space) OVER (PARTITION BY s.s_state ORDER BY s.s_floor_space DESC), 0) AS floor_space_change,
       s.s_tax_percentage,
       AVG(s.s_tax_percentage) OVER (PARTITION BY s.s_state) AS avg_state_tax_pct,
       s.s_tax_percentage - AVG(s.s_tax_percentage) OVER (PARTITION BY s.s_state) AS tax_pct_diff,
       CASE
         WHEN d.d_holiday = 'Y' THEN 'Holiday'
         WHEN d.d_weekend = 'Y' THEN 'Weekend'
         ELSE 'Weekday'
       END AS close_day_type,
       d.d_date AS closed_date
FROM store s
JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
WHERE s.s_state IS NOT NULL
ORDER BY s.s_state, floor_space_rank
LIMIT 50
