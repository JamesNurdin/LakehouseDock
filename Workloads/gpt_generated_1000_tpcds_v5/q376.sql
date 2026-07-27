SELECT
  cc.cc_name,
  sm.sm_type,
  ca.ca_state,
  hd.hd_vehicle_count,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
  SUM(cr.cr_return_amount) AS total_catalog_return_amount,
  SUM(sr.sr_return_amt) AS total_store_return_amount,
  AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
  MAX(sr.sr_return_amt) AS max_store_return_amt
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
  AND sr.sr_addr_sk = ca.ca_address_sk
WHERE cc.cc_gmt_offset = -5.00
  AND ca.ca_state = 'CA'
  AND hd.hd_vehicle_count > 0
  AND sm.sm_type = 'AIR'
GROUP BY
  cc.cc_name,
  sm.sm_type,
  ca.ca_state,
  hd.hd_vehicle_count
ORDER BY total_store_return_amount DESC
LIMIT 100
