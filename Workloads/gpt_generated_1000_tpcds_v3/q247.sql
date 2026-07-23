SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_units,
    i.i_class_id,
    sm.sm_type,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_paid_inc_ship) AS avg_net_paid_inc_ship,
    SUM(sr.sr_return_amt) AS total_return_amount,
    MIN(cs.cs_ext_tax) AS min_tax,
    MAX(cs.cs_ext_tax) AS max_tax,
    (SELECT AVG(cs2.cs_net_paid_inc_ship)
       FROM catalog_sales cs2
      WHERE cs2.cs_item_sk = i.i_item_sk) AS avg_item_net_paid
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_cdemo_sk = cd.cd_demo_sk
 AND sr.sr_addr_sk = ca.ca_address_sk
WHERE cs.cs_ext_tax > 20.00
  AND cs.cs_promo_sk IN (1076, 731)
  AND cs.cs_net_paid_inc_ship BETWEEN 1000 AND 8000
  AND i.i_units = 'Lb'
  AND i.i_class_id IN (3, 4)
  AND sm.sm_type = 'AIR'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND sr.sr_return_ship_cost > 100.00
  AND EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = cs.cs_item_sk AND sr2.sr_return_amt > 200)
GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_units, i.i_class_id, sm.sm_type, ca.ca_state, cd.cd_gender
ORDER BY total_sales DESC
LIMIT 100
