SELECT
  sm.sm_ship_mode_id,
  sm.sm_code,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_paid_inc_ship) AS total_paid
FROM catalog_sales cs
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_ext_wholesale_cost > 1500
  AND sm.sm_contract = 'HVDFCcQ'
GROUP BY sm.sm_ship_mode_id, sm.sm_code
ORDER BY total_paid DESC
LIMIT 10
