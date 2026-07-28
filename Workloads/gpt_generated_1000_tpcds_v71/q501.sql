SELECT
  sm_code,
  COUNT(DISTINCT sm_carrier) AS distinct_carrier_count
FROM tpcds.ship_mode
WHERE sm_contract = '2mM8l'
GROUP BY sm_code
HAVING COUNT(*) > 1
ORDER BY distinct_carrier_count DESC
LIMIT 100
