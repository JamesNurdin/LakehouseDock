SELECT
    sm_ship_mode_id,
    sm_type,
    sm_carrier,
    COUNT(*) AS mode_count
FROM tpcds.ship_mode
WHERE sm_code = 'AIR'
  AND sm_carrier = 'AIRBORNE'
GROUP BY sm_ship_mode_id, sm_type, sm_carrier
ORDER BY mode_count DESC
