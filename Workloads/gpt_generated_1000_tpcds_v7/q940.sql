SELECT
  cc.cc_call_center_id,
  REGEXP_EXTRACT(cc.cc_name, '(\\w+) Center', 1) AS center_type,
  sm.sm_code,
  sm.sm_contract,
  CONCAT(w.w_city, ', ', w.w_state) AS location,
  SUBSTR(w.w_street_number, 1, 1) AS street_prefix,
  SUM(cs.cs_net_profit) AS total_net_profit,
  SUM(cs.cs_quantity) AS total_quantity,
  AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE sm.sm_code LIKE 'A%'
  AND REGEXP_LIKE(sm.sm_contract, '^A[0-9]{2}[A-Z].*')
  AND cc.cc_name LIKE '%Center%'
  AND REGEXP_LIKE(cc.cc_city, '^[A-Z]{2,}$')
GROUP BY
  cc.cc_call_center_id,
  REGEXP_EXTRACT(cc.cc_name, '(\\w+) Center', 1),
  sm.sm_code,
  sm.sm_contract,
  CONCAT(w.w_city, ', ', w.w_state),
  SUBSTR(w.w_street_number, 1, 1)
ORDER BY total_net_profit DESC
LIMIT 100
