SELECT
  sm.sm_type,
  COUNT(*) AS mode_cnt
FROM
  ship_mode AS sm
WHERE
  sm.sm_code = 'AIR'
  AND sm.sm_type = 'EXPRESS'
GROUP BY
  sm.sm_type
