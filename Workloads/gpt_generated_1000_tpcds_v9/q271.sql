SELECT
  s.s_store_id,
  p.p_promo_id,
  t.t_hour,
  SUM(cr.cr_net_loss)               AS total_cr_net_loss,
  SUM(sr.sr_net_loss)               AS total_sr_net_loss,
  SUM(wr.wr_net_loss)               AS total_wr_net_loss,
  SUM(cr.cr_return_quantity)        AS total_cr_return_qty,
  SUM(sr.sr_return_quantity)        AS total_sr_return_qty,
  SUM(wr.wr_return_quantity)        AS total_wr_return_qty,
  AVG(ws.ws_sales_price)            AS avg_ws_sales_price,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
  SUM(i.inv_quantity_on_hand)       AS total_inventory_on_hand
FROM tpcds.time_dim t
INNER JOIN tpcds.store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
INNER JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
INNER JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
INNER JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
INNER JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
INNER JOIN tpcds.inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN tpcds.web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
INNER JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN tpcds.web_site webs
        ON ws.ws_web_site_sk = webs.web_site_sk
INNER JOIN tpcds.web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
       AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
WHERE t.t_hour = 14
  AND s.s_state = 'CA'
  AND cr.cr_fee > 30.00
  AND i.inv_quantity_on_hand >= 500
  AND p.p_discount_active = 'Y'
  AND ws.ws_sales_price > 100.00
  AND w.w_state = 'TX'
GROUP BY s.s_store_id, p.p_promo_id, t.t_hour
HAVING (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) > 5000
ORDER BY total_inventory_on_hand DESC
LIMIT 100
