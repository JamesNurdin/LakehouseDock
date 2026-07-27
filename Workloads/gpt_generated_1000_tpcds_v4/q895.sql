SELECT
  cr.cr_item_sk,
  hd.hd_vehicle_count,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  SUM(cr.cr_return_amount) AS total_return_amount
FROM catalog_returns AS cr
JOIN household_demographics AS hd
  ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
WHERE cr.cr_fee > 20.00
  AND hd.hd_dep_count <= 3
GROUP BY cr.cr_item_sk, hd.hd_vehicle_count
ORDER BY total_return_amount DESC
LIMIT 100
