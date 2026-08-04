SELECT sm_carrier,
       COUNT(*) AS mode_count
FROM tpcds.ship_mode
WHERE sm_carrier = 'DHL'
  AND sm_contract = 'Ek'
GROUP BY sm_carrier
