SELECT DISTINCT
  sm_ship_mode_id,
  sm_carrier,
  sm_contract
FROM tpcds.ship_mode
WHERE sm_carrier = 'DHL'
  AND sm_contract = 'I3uCelXtjP'
LIMIT 100
