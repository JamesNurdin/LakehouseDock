WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),
  ss_distinct AS (
    SELECT DISTINCT
      ss_item_sk,
      ss_sold_time_sk,
      ss_net_paid
    FROM store_sales
  )
SELECT
  i.i_item_id,
  i.i_brand,
  w.w_warehouse_name,
  cc.cc_name,
  r.r_reason_desc,
  SUM(cs.cs_net_paid) AS total_catalog_sales,
  SUM(ss.ss_net_paid) AS total_store_sales,
  SUM(cr.cr_net_loss) AS total_return_loss,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category,
  MIN(inv_agg.total_qty_on_hand) AS min_qty_on_hand,
  MAX(inv_agg.total_qty_on_hand) AS max_qty_on_hand
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN inv_agg
  ON i.i_item_sk = inv_agg.inv_item_sk
  AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN ss_distinct ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td
  ON cs.cs_sold_time_sk = td.t_time_sk
  AND ss.ss_sold_time_sk = td.t_time_sk
WHERE r.r_reason_desc = 'Did not get it on time'
  AND cd.cd_education_status = 'Advanced Degree'
  AND cd.cd_purchase_estimate > 5000
GROUP BY
  i.i_item_id,
  i.i_brand,
  w.w_warehouse_name,
  cc.cc_name,
  r.r_reason_desc
ORDER BY total_catalog_sales DESC
LIMIT 100
