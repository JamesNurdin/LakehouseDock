SELECT
  sm_carrier,
  COUNT(DISTINCT sm_ship_mode_id) AS distinct_mode_cnt
FROM
  ship_mode
WHERE
  sm_code = 'AIR'
  AND sm_contract = 'Xjy3ZPuiDjzHlRx14Z3'
GROUP BY
  sm_carrier
ORDER BY
  distinct_mode_cnt DESC
LIMIT 10
