SELECT
  sm.sm_ship_mode_id,
  sm.sm_carrier,
  sm.sm_type,
  COUNT(*) AS mode_cnt
FROM tpcds.ship_mode AS sm
WHERE sm.sm_carrier IN ('USPS', 'DHL')
  AND sm.sm_type = 'OVERNIGHT'
GROUP BY sm.sm_ship_mode_id, sm.sm_carrier, sm.sm_type
LIMIT 100
