SELECT
  td.t_am_pm AS am_pm,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
  COUNT(*) AS return_count
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
WHERE td.t_minute = 2
  AND cr.cr_return_ship_cost > 100
GROUP BY td.t_am_pm
ORDER BY total_return_amount DESC
