SELECT
  cs.cs_order_number,
  cs.cs_net_paid_inc_tax,
  sm.sm_ship_mode_id,
  sm.sm_carrier
FROM tpcds.catalog_sales AS cs
INNER JOIN tpcds.ship_mode AS sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_contract = 'Ek'
  AND cs.cs_quantity > 30
LIMIT 100
