SELECT
  ship_mode.sm_type,
  COUNT(*) AS mode_count
FROM
  tpcds.ship_mode
WHERE
  ship_mode.sm_ship_mode_sk > 10
  AND ship_mode.sm_contract = 'I3uCelXtjP'
GROUP BY
  ship_mode.sm_type
ORDER BY
  mode_count DESC
LIMIT 100
