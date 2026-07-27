WITH max_inv AS (
    SELECT inv_warehouse_sk,
           MAX(inv_quantity_on_hand) AS max_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    i.i_category,
    w.w_warehouse_name,
    cc.cc_name               AS call_center_name,
    cp.cp_department,
    p.p_promo_name,
    SUM(ss.ss_net_profit)    AS total_store_profit,
    SUM(ws.ws_net_profit)    AS total_web_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_net_loss)      AS total_store_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    MAX(CASE WHEN inv.inv_quantity_on_hand = max_inv.max_qty THEN 1 ELSE 0 END) AS has_max_inventory
FROM catalog_returns cr
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref
  ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
  ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ref
  ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
  ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN max_inv
  ON max_inv.inv_warehouse_sk = w.w_warehouse_sk
-- Store sales side
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_ss
  ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN promotion p_ss
  ON ss.ss_promo_sk = p_ss.p_promo_sk
-- Store returns side
LEFT JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
-- Web sales side
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN promotion p_ws
  ON ws.ws_promo_sk = p_ws.p_promo_sk
WHERE td_cr.t_hour BETWEEN 8 AND 20
GROUP BY
    i.i_category,
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_department,
    p.p_promo_name
ORDER BY total_store_profit DESC
LIMIT 100
