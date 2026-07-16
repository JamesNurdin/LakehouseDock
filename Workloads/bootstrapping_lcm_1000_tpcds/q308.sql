SELECT
    d.d_year,
    d.d_current_month,
    s.s_state,
    COUNT(*) AS closures,
    COUNT(DISTINCT s.s_store_sk) AS distinct_stores_closed,
    SUM(s.s_number_employees) AS total_employees,
    AVG(s.s_tax_percentage) AS avg_tax_pct,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END) AS holiday_closures,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN 1 ELSE 0 END) AS weekend_closures,
    SUM(s.s_floor_space) / NULLIF(SUM(s.s_number_employees), 0) AS floor_space_per_employee
FROM date_dim AS d
JOIN store AS s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year IS NOT NULL
  AND s.s_state IS NOT NULL
GROUP BY d.d_year, d.d_current_month, s.s_state
HAVING COUNT(*) > 5
ORDER BY d.d_year DESC, d.d_current_month ASC, s.s_state
LIMIT 100
