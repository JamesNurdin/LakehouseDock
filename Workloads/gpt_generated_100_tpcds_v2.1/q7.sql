SELECT sm.sm_ship_mode_id,
       sm.sm_type,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_count
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_warehouse_sk = 9
  AND sm.sm_contract = 'P7FBIt8yd'
GROUP BY sm.sm_ship_mode_id, sm.sm_type
LIMIT 100
