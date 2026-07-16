WITH ship_f AS (
  SELECT sm_ship_mode_sk, sm_type, sm_carrier
  FROM ship_mode
  WHERE sm_carrier IN ('UPS', 'FEDEX')
    AND sm_type LIKE 'EXPRESS%'
),
wh_f AS (
  SELECT w_warehouse_sk, w_city, w_state, w_warehouse_sq_ft, w_gmt_offset
  FROM warehouse
  WHERE w_gmt_offset BETWEEN -5 AND 5
    AND w_warehouse_sq_ft > 1000
),
web_f AS (
  SELECT web_site_sk, web_state, web_city, web_tax_percentage
  FROM web_site
  WHERE web_tax_percentage BETWEEN 0.05 AND 0.2
)
SELECT
  sm_type,
  w_state,
  web_state,
  warehouse_cnt,
  total_sq_ft,
  avg_tax_pct,
  ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_sq_ft DESC) AS rn
FROM (
  SELECT
    s.sm_type,
    w.w_state,
    ws.web_state,
    COUNT(DISTINCT w.w_warehouse_sk) AS warehouse_cnt,
    SUM(w.w_warehouse_sq_ft) AS total_sq_ft,
    AVG(ws.web_tax_percentage) AS avg_tax_pct,
    COUNT(*) AS row_cnt
  FROM ship_f s
  JOIN wh_f w ON true
  JOIN web_f ws ON true
  GROUP BY s.sm_type, w.w_state, ws.web_state
  HAVING COUNT(*) > 100
) agg
ORDER BY total_sq_ft DESC
LIMIT 100
