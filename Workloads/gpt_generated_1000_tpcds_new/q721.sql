WITH inv_filtered AS (
    SELECT inv_item_sk, inv_warehouse_sk
    FROM inventory inv2
    WHERE inv2.inv_quantity_on_hand > 500
)
SELECT
    i.i_item_id,
    cp.cp_department,
    w.w_warehouse_name,
    sm.sm_type,
    td_cs.t_hour,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'HasReturn' ELSE 'NoReturn' END AS return_flag,
    SUM(cs.cs_net_paid) AS total_catalog_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_net_paid) AS total_store_paid,
    SUM(sr.sr_return_amt) AS total_store_return,
    SUM(ws.ws_net_paid) AS total_web_paid,
    SUM(wr.wr_return_amt) AS total_web_return,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
FROM item i
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN time_dim td_cs ON td_cs.t_time_sk = cs.cs_sold_time_sk
JOIN customer_demographics cd_bill ON cd_bill.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd_bill ON hd_bill.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN time_dim td_cr ON td_cr.t_time_sk = cr.cr_returned_time_sk
JOIN customer_demographics cd_refund ON cd_refund.cd_demo_sk = cr.cr_refunded_cdemo_sk
JOIN household_demographics hd_refund ON hd_refund.hd_demo_sk = cr.cr_refunded_hdemo_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_ss ON td_ss.t_time_sk = ss.ss_sold_time_sk
JOIN customer_demographics cd_ss ON cd_ss.cd_demo_sk = ss.ss_cdemo_sk
JOIN household_demographics hd_ss ON hd_ss.hd_demo_sk = ss.ss_hdemo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr ON td_sr.t_time_sk = sr.sr_return_time_sk
JOIN customer_demographics cd_sr ON cd_sr.cd_demo_sk = sr.sr_cdemo_sk
JOIN household_demographics hd_sr ON hd_sr.hd_demo_sk = sr.sr_hdemo_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws ON td_ws.t_time_sk = ws.ws_sold_time_sk
JOIN customer_demographics cd_ws ON cd_ws.cd_demo_sk = ws.ws_bill_cdemo_sk
JOIN household_demographics hd_ws ON hd_ws.hd_demo_sk = ws.ws_bill_hdemo_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
JOIN ship_mode sm_ws ON sm_ws.sm_ship_mode_sk = ws.ws_ship_mode_sk
JOIN warehouse w_ws ON w_ws.w_warehouse_sk = ws.ws_warehouse_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN time_dim td_wr ON td_wr.t_time_sk = wr.wr_returned_time_sk
JOIN customer_demographics cd_wr ON cd_wr.cd_demo_sk = wr.wr_refunded_cdemo_sk
JOIN household_demographics hd_wr ON hd_wr.hd_demo_sk = wr.wr_refunded_hdemo_sk
JOIN web_page wp_wr ON wp_wr.wp_web_page_sk = wr.wr_web_page_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE cr.cr_return_amount > 1000
  AND w.w_zip = '64593'
  AND sm.sm_type = 'AIR'
  AND i.i_current_price BETWEEN 50 AND 200
  AND td_cs.t_hour BETWEEN 9 AND 17
  AND EXISTS (SELECT 1 FROM inv_filtered f WHERE f.inv_item_sk = i.i_item_sk)
GROUP BY CUBE (i.i_item_id, cp.cp_department, w.w_warehouse_name, sm.sm_type, td_cs.t_hour)
ORDER BY total_catalog_paid DESC
OFFSET 0
LIMIT 100
