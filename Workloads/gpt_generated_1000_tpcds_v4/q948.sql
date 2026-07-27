WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_net_paid,
       cs.cs_net_profit,
       i2.i_brand,
       i2.i_category,
       w2.w_warehouse_name,
       sm2.sm_type,
       hd2.hd_buy_potential,
       cr.cr_return_amount,
       sr.sr_return_amt,
       r1.r_reason_desc AS store_return_reason,
       r2.r_reason_desc AS catalog_return_reason
   FROM store_returns sr
   JOIN item i1
     ON sr.sr_item_sk = i1.i_item_sk
   JOIN reason r1
     ON sr.sr_reason_sk = r1.r_reason_sk
   JOIN household_demographics hd1
     ON sr.sr_hdemo_sk = hd1.hd_demo_sk
   JOIN catalog_returns cr
     ON cr.cr_item_sk = i1.i_item_sk
   JOIN reason r2
     ON cr.cr_reason_sk = r2.r_reason_sk
   JOIN call_center cc1
     ON cr.cr_call_center_sk = cc1.cc_call_center_sk
   JOIN ship_mode sm1
     ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
   JOIN warehouse w1
     ON cr.cr_warehouse_sk = w1.w_warehouse_sk
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
   JOIN item i2
     ON cs.cs_item_sk = i2.i_item_sk
   JOIN ship_mode sm2
     ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN call_center cc2
     ON cs.cs_call_center_sk = cc2.cc_call_center_sk
   JOIN household_demographics hd2
     ON cs.cs_bill_hdemo_sk = hd2.hd_demo_sk
   JOIN warehouse w2
     ON cs.cs_warehouse_sk = w2.w_warehouse_sk
   JOIN inventory inv
     ON inv.inv_item_sk = i2.i_item_sk
    AND inv.inv_warehouse_sk = w2.w_warehouse_sk
   WHERE sm2.sm_type = 'REGULAR'
     AND hd2.hd_buy_potential = '5001-10000'
     AND inv.inv_quantity_on_hand > 100
),
aggregated AS (
   SELECT
       cs_order_number,
       cs_sold_date_sk,
       i_brand,
       i_category,
       w_warehouse_name,
       sm_type,
       SUM(cs_net_paid) AS total_net_paid,
       SUM(cs_net_profit) AS total_net_profit,
       SUM(cr_return_amount) AS total_catalog_return_amount,
       SUM(sr_return_amt) AS total_store_return_amount
   FROM base
   GROUP BY
       cs_order_number,
       cs_sold_date_sk,
       i_brand,
       i_category,
       w_warehouse_name,
       sm_type
   HAVING SUM(cs_net_profit) > 5000
)
SELECT
   DISTINCT a.cs_order_number,
   a.cs_sold_date_sk,
   a.i_brand,
   a.i_category,
   a.w_warehouse_name,
   a.sm_type,
   a.total_net_paid,
   a.total_net_profit,
   a.total_catalog_return_amount,
   a.total_store_return_amount,
   ROW_NUMBER() OVER (PARTITION BY a.cs_order_number ORDER BY a.cs_sold_date_sk DESC) AS rn
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 100
