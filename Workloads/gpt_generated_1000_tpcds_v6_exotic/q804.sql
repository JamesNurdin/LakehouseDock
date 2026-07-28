WITH agg AS (
  SELECT
    d.d_fy_year,
    c.cc_state,
    COUNT(DISTINCT c.cc_call_center_id) AS call_center_cnt,
    SUM(c.cc_employees) AS total_employees,
    AVG(c.cc_tax_percentage) AS avg_tax_pct,
    MAX(c.cc_tax_percentage) AS max_tax_pct,
    CASE WHEN AVG(c.cc_tax_percentage) > 0.20 THEN 'HIGH' ELSE 'NORMAL' END AS tax_category
  FROM call_center c
  JOIN date_dim d
    ON c.cc_closed_date_sk = d.d_date_sk
  WHERE d.d_fy_year = 1908
    AND d.d_first_dom = 2415386
    AND c.cc_zip = '39275'
    AND c.cc_employees >= 100
  GROUP BY d.d_fy_year, c.cc_state
)
SELECT
  agg.d_fy_year,
  agg.cc_state,
  agg.call_center_cnt,
  agg.total_employees,
  agg.avg_tax_pct,
  agg.max_tax_pct,
  agg.tax_category,
  ROW_NUMBER() OVER (PARTITION BY agg.d_fy_year ORDER BY agg.total_employees DESC) AS state_employee_rank
FROM agg
ORDER BY agg.total_employees DESC
LIMIT 100
