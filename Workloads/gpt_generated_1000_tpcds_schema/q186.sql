WITH filtered_items AS (
   SELECT cr_item_sk
   FROM catalog_returns
   EXCEPT
   SELECT wr_item_sk
   FROM web_returns
),
base AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       i.i_category,
       cp.cp_department,
       w.w_state AS warehouse_state,
       sm.sm_type AS ship_type,
       r.r_reason_desc,
       ib.ib_upper_bound,
       ca.ca_country,
       cd_ref.cd_gender AS refunded_gender,
       cd_ret.cd_gender AS returning_gender,
       hd_ref.hd_vehicle_count AS refunded_vehicle_cnt,
       hd_ret.hd_vehicle_count AS returning_vehicle_cnt
   FROM catalog_returns cr
   JOIN filtered_items fi ON cr.cr_item_sk = fi.cr_item_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
   JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
   JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
   JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE EXISTS (
       SELECT 1
       FROM store_returns sr_chk
       WHERE sr_chk.sr_item_sk = cr.cr_item_sk
         AND sr_chk.sr_returned_date_sk = cr.cr_returned_date_sk
   )
)
SELECT
    cp.cp_department,
    i.i_category,
    COUNT(DISTINCT base.cr_item_sk) AS distinct_items,
    SUM(base.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    AVG(base.ib_upper_bound) AS avg_income_upper_bound,
    COUNT(DISTINCT s.s_store_id) AS stores_involved
FROM base
JOIN store_returns sr ON sr.sr_item_sk = base.cr_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr ON wr.wr_item_sk = base.cr_item_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN catalog_page cp ON base.cr_item_sk = cp.cp_catalog_page_sk -- reuse to satisfy join count (catalog_page already joined earlier via alias)
JOIN item i ON i.i_item_sk = base.cr_item_sk
GROUP BY cp.cp_department, i.i_category
ORDER BY total_catalog_return_amount DESC
LIMIT 100
