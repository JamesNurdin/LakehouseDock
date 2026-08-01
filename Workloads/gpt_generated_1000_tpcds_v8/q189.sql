WITH base AS (
   SELECT
       i.i_item_id,
       i.i_product_name,
       i.i_color,
       i.i_size,
       w.w_warehouse_name,
       cc.cc_name,
       cp.cp_description,
       sm.sm_type,
       c.c_customer_id,
       cd.cd_gender,
       ss.ss_net_paid,
       ss.ss_quantity,
       sr.sr_return_amt,
       cr.cr_return_amount,
       wr.wr_return_amt,
       p.p_cost,
       inv.inv_quantity_on_hand,
       r.r_reason_desc,
       cs.cs_ext_discount_amt
   FROM item i
   INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
   LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
   LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
   LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
   LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
   LEFT JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
   LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
   LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
   LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
   LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
   LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   WHERE i.i_size = 'large'
     AND w.w_state = 'NY'
     AND c.c_birth_year = 1975
     AND EXISTS (
         SELECT 1 FROM inventory inv2
         WHERE inv2.inv_item_sk = i.i_item_sk
           AND inv2.inv_quantity_on_hand > 500
     )
)
SELECT
   i_item_id,
   i_product_name,
   i_color,
   i_size,
   w_warehouse_name,
   cc_name,
   COUNT(DISTINCT c_customer_id) AS distinct_customers,
   SUM(ss_net_paid) AS total_sales,
   SUM(ss_quantity) AS total_quantity_sold,
   SUM(sr_return_amt) AS total_store_returns,
   SUM(cr_return_amount) AS total_catalog_returns,
   SUM(wr_return_amt) AS total_web_returns,
   AVG(cs_ext_discount_amt) AS avg_discount_amount,
   MAX(inv_quantity_on_hand) AS max_inventory_on_hand,
   MIN(r_reason_desc) FILTER (WHERE r_reason_desc IS NOT NULL) AS sample_reason
FROM base
GROUP BY
   i_item_id,
   i_product_name,
   i_color,
   i_size,
   w_warehouse_name,
   cc_name
ORDER BY total_sales DESC
LIMIT 100
