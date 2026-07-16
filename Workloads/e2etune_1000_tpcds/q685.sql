WITH store_agg AS (
  SELECT
    s.s_state,
    s.s_city,
    COUNT(*) AS store_cnt,
    SUM(s.s_floor_space) AS total_floor_space,
    AVG(s.s_tax_percentage) AS avg_tax,
    SUM(s.s_number_employees) AS total_employees
  FROM store s
  WHERE s.s_rec_start_date >= DATE '2000-01-01'
    AND s.s_tax_percentage BETWEEN 0.01 AND 0.10
    AND s.s_floor_space > 5000000
  GROUP BY s.s_state, s.s_city
),
web_agg AS (
  SELECT
    w.web_state,
    AVG(w.web_gmt_offset) AS avg_gmt_offset,
    AVG(w.web_tax_percentage) AS avg_web_tax
  FROM web_site w
  WHERE w.web_open_date_sk IS NOT NULL
    AND w.web_tax_percentage < 0.08
  GROUP BY w.web_state
)
SELECT
  sa.s_state,
  sa.s_city,
  sa.store_cnt,
  sa.total_floor_space,
  sa.avg_tax,
  wa.avg_gmt_offset,
  (sa.total_employees * 1.0) / NULLIF(sa.total_floor_space, 0) AS emp_per_sqft,
  RANK() OVER (PARTITION BY sa.s_state ORDER BY sa.total_floor_space DESC) AS city_floor_space_rank
FROM store_agg sa
LEFT JOIN web_agg wa
  ON sa.s_state = wa.web_state
WHERE wa.avg_gmt_offset IS NOT NULL
ORDER BY sa.total_floor_space DESC
LIMIT 100
