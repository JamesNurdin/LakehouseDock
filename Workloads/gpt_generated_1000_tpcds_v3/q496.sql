SELECT
    r.r_reason_desc,
    sm.sm_carrier,
    s.s_state,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
    SUM(ws.ws_net_profit) AS total_web_sales_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(cs.cs_quantity) AS total_catalog_quantity_sold,
    SUM(ws.ws_quantity) AS total_web_quantity_sold,
    SUM(sr.sr_return_quantity) AS total_store_quantity_returned,
    SUM(wr.wr_return_quantity) AS total_web_quantity_returned,
    AVG(i.i_current_price) AS avg_item_price
FROM item i
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
  AND cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
  AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
  AND sr.sr_reason_sk = r.r_reason_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_order_number = ws.ws_order_number
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
  AND wr.wr_reason_sk = r.r_reason_sk
WHERE
    sm.sm_carrier = 'PRIVATECARRIER'
    AND i.i_brand_id = 12
    AND s.s_state = 'CA'
    AND r.r_reason_desc = 'Customer Not Satisfied'
GROUP BY
    r.r_reason_desc,
    sm.sm_carrier,
    s.s_state,
    i.i_category
ORDER BY total_catalog_sales_profit DESC
LIMIT 100
