SELECT
  ship_mode.sm_type,
  SUM(catalog_returns.cr_return_amount) AS total_return_amount
FROM catalog_returns
JOIN ship_mode
  ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
WHERE ship_mode.sm_code = 'AIR'
  AND catalog_returns.cr_store_credit > 10
GROUP BY ship_mode.sm_type
ORDER BY total_return_amount DESC
