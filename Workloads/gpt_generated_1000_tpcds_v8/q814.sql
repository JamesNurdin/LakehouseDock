WITH
  sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_item_sk,
      cs.cs_order_number,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_addr_sk
    FROM catalog_sales cs
    WHERE cs.cs_item_sk IN (
          SELECT i_item_sk FROM item WHERE i_units = 'Dozen'
        )
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr WHERE cr.cr_order_number = cs.cs_order_number
        )
  ),
  inventory_sample AS (
    SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  order_numbers_diff AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
  ),
  order_numbers_common AS (
    SELECT cs_order_number FROM catalog_sales
    INTERSECT
    SELECT cr_order_number FROM catalog_returns
  )
SELECT
  d.d_year,
  i.i_item_id,
  i.i_category,
  w.w_warehouse_name,
  sm.sm_type,
  cc.cc_name,
  cp.cp_catalog_page_number,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  ca.ca_city,
  SUM(s.cs_net_paid) AS total_net_paid,
  SUM(s.cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT s.cs_order_number) AS distinct_orders,
  CASE WHEN SUM(s.cs_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  RANK() OVER (PARTITION BY i.i_item_id ORDER BY SUM(s.cs_net_paid) DESC) AS sales_rank,
  ROW_NUMBER() OVER (ORDER BY SUM(s.cs_net_paid) DESC) AS overall_rank
FROM sales s
JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON s.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN inventory_sample inv
  ON inv.inv_item_sk = i.i_item_sk
  AND inv.inv_warehouse_sk = w.w_warehouse_sk
  AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr
  ON s.cs_item_sk = cr.cr_item_sk
  AND s.cs_order_number = cr.cr_order_number
LEFT JOIN store_returns sr
  ON i.i_item_sk = sr.sr_item_sk
  AND d.d_date_sk = sr.sr_returned_date_sk
  AND c.c_customer_sk = sr.sr_customer_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND w.w_state = 'CA'
  AND s.cs_order_number IN (SELECT cs_order_number FROM order_numbers_common)
GROUP BY
  d.d_year,
  i.i_item_id,
  i.i_category,
  w.w_warehouse_name,
  sm.sm_type,
  cc.cc_name,
  cp.cp_catalog_page_number,
  c.c_first_name,
  c.c_last_name,
  cd.cd_gender,
  ca.ca_city
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
