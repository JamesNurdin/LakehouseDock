SELECT
  cc.cc_division,
  i.i_class_id,
  sm.sm_type,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  AVG(cs.cs_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  MIN(cs.cs_ext_wholesale_cost) AS min_wholesale,
  MAX(cs.cs_ext_wholesale_cost) AS max_wholesale,
  GROUPING(cc.cc_division) AS g_division,
  GROUPING(i.i_class_id) AS g_class,
  GROUPING(sm.sm_type) AS g_ship_type
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer_address ca_bill
  ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN tpcds.customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE cs.cs_ext_wholesale_cost >= 3000
  AND cs.cs_ext_discount_amt BETWEEN 1000 AND 4000
  AND cs.cs_ship_date_sk IN (2450900, 2450837, 2450862)
  AND i.i_class_id IN (9, 10)
  AND i.i_units = 'Dozen'
  AND cc.cc_division = 1
  AND ca_bill.ca_state = 'CA'
  AND ca_ship.ca_state = 'CA'
GROUP BY GROUPING SETS (
    (cc.cc_division, i.i_class_id, sm.sm_type),
    (cc.cc_division, i.i_class_id),
    (cc.cc_division, sm.sm_type),
    (i.i_class_id, sm.sm_type),
    (cc.cc_division),
    (i.i_class_id),
    (sm.sm_type),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
