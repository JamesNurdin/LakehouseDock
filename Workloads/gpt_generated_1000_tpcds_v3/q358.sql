WITH sales_base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_hdemo_sk,
    ss.ss_store_sk,
    ss.ss_ticket_number,
    ss.ss_quantity,
    ss.ss_wholesale_cost,
    ss.ss_ext_discount_amt,
    ss.ss_ext_sales_price,
    ss.ss_net_paid,
    ss.ss_net_profit,
    td.t_hour,
    hd.hd_vehicle_count,
    hd.hd_dep_count
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE ss.ss_wholesale_cost > 20
    AND ss.ss_ext_discount_amt < 100
    AND hd.hd_vehicle_count >= 2
    AND hd.hd_dep_count <= 5
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT
  cc.cc_call_center_id,
  cp.cp_catalog_page_id,
  cr.cr_return_amount,
  sm.sm_type,
  w.w_warehouse_name,
  i.inv_quantity_on_hand,
  r.r_reason_desc,
  swd.ss_ticket_number,
  swd.ss_net_profit,
  DENSE_RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY swd.ss_net_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY cp.cp_catalog_page_id ORDER BY cr.cr_return_amount DESC) AS return_amount_rn
FROM sales_base swd
JOIN store_returns sr
  ON sr.sr_item_sk = swd.ss_item_sk
 AND sr.sr_ticket_number = swd.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_amount > 50
  AND i.inv_quantity_on_hand > 0
  AND cc.cc_gmt_offset BETWEEN -5 AND 5
  AND sm.sm_carrier IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_reason_sk = r.r_reason_sk
      AND wp.wp_type = 'Product'
  )
ORDER BY cc.cc_call_center_id, profit_rank
LIMIT 100
