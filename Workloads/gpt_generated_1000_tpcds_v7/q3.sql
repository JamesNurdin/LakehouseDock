SELECT
    sm_ship_mode_id,
    sm_type,
    sm_carrier
FROM tpcds.ship_mode
WHERE sm_contract = 'A5BYO1qH8HGTTN'
  AND sm_carrier = 'UPS'
ORDER BY sm_ship_mode_sk
LIMIT 100
