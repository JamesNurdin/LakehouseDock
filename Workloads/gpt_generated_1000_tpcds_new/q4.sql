WITH open_cc AS (
  SELECT
    cc.cc_state AS state,
    cc.cc_market_manager AS market_manager,
    cc.cc_employees AS employees,
    cc.cc_sq_ft AS sq_ft
  FROM call_center cc
  JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
  WHERE d.d_current_year = 'Y'
    AND cc.cc_state IS NOT NULL
),
closed_cc AS (
  SELECT
    cc.cc_state AS state,
    cc.cc_market_manager AS market_manager,
    cc.cc_employees AS employees,
    cc.cc_sq_ft AS sq_ft
  FROM call_center cc
  JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
  WHERE d.d_current_year = 'N'
    AND cc.cc_state IS NOT NULL
)
SELECT
  state,
  market_manager,
  SUM(employees) AS total_employees,
  SUM(sq_ft) AS total_sq_ft,
  COUNT(*) AS record_cnt
FROM (
  SELECT state, market_manager, employees, sq_ft FROM open_cc
  UNION ALL
  SELECT state, market_manager, employees, sq_ft FROM closed_cc
) u
GROUP BY GROUPING SETS (
  (state),
  (market_manager),
  (state, market_manager)
)
ORDER BY total_employees DESC
LIMIT 100
