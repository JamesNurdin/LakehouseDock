SELECT DISTINCT ship_mode.sm_ship_mode_id, ship_mode.sm_carrier, ship_mode.sm_type
FROM tpcds.ship_mode
WHERE ship_mode.sm_contract = 'OrDuVy2H'
  AND ship_mode.sm_carrier = 'DIAMOND'
LIMIT 100
