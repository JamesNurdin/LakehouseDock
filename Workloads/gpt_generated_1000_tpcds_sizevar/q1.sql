SELECT
    sm_ship_mode_id,
    sm_type,
    COUNT(*) AS mode_count
FROM tpcds.ship_mode
WHERE sm_contract IN ('Ek', 'P7FBIt8yd')
  AND sm_ship_mode_sk > 10
GROUP BY sm_ship_mode_id, sm_type
ORDER BY mode_count DESC
