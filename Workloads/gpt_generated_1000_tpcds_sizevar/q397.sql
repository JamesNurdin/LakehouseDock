SELECT
  sm.sm_carrier,
  SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
  COUNT(*) AS order_count
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_ext_ship_cost > 500
  AND sm.sm_carrier = 'DIAMOND'
GROUP BY sm.sm_carrier
