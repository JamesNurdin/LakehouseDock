WITH sales_demo AS (
   SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_profit,
      ss.ss_hdemo_sk,
      ss.ss_customer_sk,
      ss.ss_promo_sk,
      ss.ss_ticket_number
   FROM store_sales ss
   WHERE ss.ss_sales_price > 100
     AND ss.ss_quantity >= 1
),

demo_filtered AS (
   SELECT *
   FROM household_demographics hd
   WHERE hd.hd_income_band_sk IN (10, 13)
     AND hd.hd_dep_count >= 1
     AND hd.hd_vehicle_count > 0
),

joined1 AS (
   SELECT
      sd.*,
      hd.hd_demo_sk,
      hd.hd_buy_potential
   FROM sales_demo sd
   JOIN demo_filtered hd
     ON sd.ss_hdemo_sk = hd.hd_demo_sk
),

store_filtered AS (
   SELECT *
   FROM store s
   WHERE s.s_state = 'CA'
     AND s.s_rec_start_date >= DATE '2001-01-01'
     AND s.s_rec_end_date <= DATE '2005-12-31'
),

joined2 AS (
   SELECT
      j1.*,
      s.s_store_id,
      s.s_store_name,
      s.s_market_id,
      s.s_market_desc
   FROM joined1 j1
   JOIN store_filtered s
     ON j1.ss_store_sk = s.s_store_sk
),

returns_filtered AS (
   SELECT *
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity > 0
     AND cr.cr_return_amount > 0
),

joined3 AS (
   SELECT
      j2.*,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cr.cr_warehouse_sk,
      cr.cr_reason_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk
   FROM joined2 j2
   JOIN returns_filtered cr
     ON cr.cr_refunded_hdemo_sk = j2.hd_demo_sk
),

call_center_filtered AS (
   SELECT *
   FROM call_center cc
   WHERE cc.cc_mkt_class LIKE '%National%'
     AND cc.cc_sq_ft > 0
),

joined4 AS (
   SELECT
      j3.*,
      cc.cc_call_center_id,
      cc.cc_name,
      cc.cc_mkt_desc
   FROM joined3 j3
   JOIN call_center_filtered cc
     ON j3.cr_call_center_sk = cc.cc_call_center_sk
),

catalog_page_filtered AS (
   SELECT *
   FROM catalog_page cp
   WHERE cp.cp_department = 'Sports'
),

joined5 AS (
   SELECT
      j4.*,
      cp.cp_catalog_page_id,
      cp.cp_description,
      cp.cp_type
   FROM joined4 j4
   JOIN catalog_page_filtered cp
     ON j4.cr_catalog_page_sk = cp.cp_catalog_page_sk
),

reason_filtered AS (
   SELECT *
   FROM reason r
   WHERE r.r_reason_desc IS NOT NULL
),

joined6 AS (
   SELECT
      j5.*,
      r.r_reason_desc
   FROM joined5 j5
   JOIN reason_filtered r
     ON j5.cr_reason_sk = r.r_reason_sk
),

warehouse_filtered AS (
   SELECT *
   FROM warehouse w
   WHERE w.w_state = 'CA'
),

joined7 AS (
   SELECT
      j6.*,
      w.w_warehouse_id,
      w.w_warehouse_name,
      w.w_gmt_offset
   FROM joined6 j6
   JOIN warehouse_filtered w
     ON j6.cr_warehouse_sk = w.w_warehouse_sk
),

inventory_filtered AS (
   SELECT *
   FROM inventory inv
   WHERE inv.inv_quantity_on_hand > 10
),

final_join AS (
   SELECT
      j7.*,
      inv.inv_quantity_on_hand
   FROM joined7 j7
   JOIN inventory_filtered inv
     ON inv.inv_warehouse_sk = j7.cr_warehouse_sk
)
SELECT
   final.s_store_id,
   final.s_store_name,
   final.cc_call_center_id,
   final.cp_catalog_page_id,
   final.r_reason_desc,
   final.w_warehouse_name,
   final.ss_sales_price,
   final.ss_quantity,
   CASE WHEN final.ss_quantity > 5 THEN 'High' ELSE 'Low' END AS quantity_flag,
   SUM(final.cr_return_amount) OVER (PARTITION BY final.s_store_id ORDER BY final.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount,
   ROW_NUMBER() OVER (PARTITION BY final.s_store_id ORDER BY final.ss_sales_price DESC) AS store_sales_rank,
   dim.dim_flag
FROM final_join final
CROSS JOIN (VALUES ('X'), ('Y')) AS dim(dim_flag)
ORDER BY final.s_store_id, store_sales_rank
LIMIT 100
