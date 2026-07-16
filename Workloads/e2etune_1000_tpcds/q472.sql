WITH cc_agg AS (
  SELECT
    cc_country,
    cc_state,
    COUNT(*) AS cc_cnt,
    SUM(cc_employees) AS total_employees,
    AVG(cc_employees) AS avg_employees,
    SUM(cc_sq_ft) AS total_sq_ft
  FROM call_center
  WHERE cc_gmt_offset = -5.00
    AND cc_employees > 1000000
  GROUP BY cc_country, cc_state
),
wh_agg AS (
  SELECT
    w_country,
    w_state,
    COUNT(*) AS wh_cnt,
    SUM(w_warehouse_sq_ft) AS total_wh_sq_ft,
    AVG(w_warehouse_sq_ft) AS avg_wh_sq_ft
  FROM warehouse
  WHERE w_warehouse_sq_ft > 50000
  GROUP BY w_country, w_state
),
ws_agg AS (
  SELECT
    web_country,
    web_state,
    COUNT(*) AS ws_cnt,
    AVG(web_tax_percentage) AS avg_tax_pct
  FROM web_site
  WHERE web_tax_percentage IS NOT NULL
  GROUP BY web_country, web_state
),
sm_agg AS (
  SELECT
    sm_type,
    COUNT(*) AS sm_cnt
  FROM ship_mode
  WHERE sm_type = 'AIR'
  GROUP BY sm_type
)
SELECT
  cc.cc_country AS country,
  cc.cc_state AS state,
  cc.cc_cnt AS call_center_count,
  cc.total_employees,
  cc.avg_employees,
  RANK() OVER (PARTITION BY cc.cc_country ORDER BY cc.total_employees DESC) AS cc_state_employee_rank,
  wh.wh_cnt AS warehouse_count,
  wh.total_wh_sq_ft,
  ws.ws_cnt AS web_site_count,
  ws.avg_tax_pct,
  sm.sm_cnt AS ship_mode_count
FROM cc_agg cc
JOIN wh_agg wh
  ON cc.cc_country = wh.w_country
 AND cc.cc_state = wh.w_state
JOIN ws_agg ws
  ON cc.cc_country = ws.web_country
 AND cc.cc_state = ws.web_state
JOIN sm_agg sm
  ON TRUE
WHERE cc.total_employees > 5000000
ORDER BY cc.total_employees DESC
LIMIT 100
