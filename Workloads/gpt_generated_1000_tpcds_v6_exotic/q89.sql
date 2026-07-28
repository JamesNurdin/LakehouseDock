WITH store_ret AS (
  SELECT r.r_reason_desc AS reason_desc,
         td.t_hour AS hour,
         sr.sr_return_amt AS return_amt
  FROM store_returns sr
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE s.s_state = 'CA'
),
catalog_ret AS (
  SELECT r.r_reason_desc AS reason_desc,
         td.t_hour AS hour,
         cr.cr_return_amount AS return_amt
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE sm.sm_code = 'AIR'
)
SELECT
  reason_desc,
  hour,
  SUM(return_amt) AS total_return
FROM (
  SELECT reason_desc, hour, return_amt FROM store_ret
  UNION ALL
  SELECT reason_desc, hour, return_amt FROM catalog_ret
) u
GROUP BY GROUPING SETS ((reason_desc, hour), (reason_desc), ( ))
ORDER BY reason_desc, hour
LIMIT 100
