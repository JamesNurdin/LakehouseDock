WITH filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 50
      AND i_category = 'Electronics'
      AND i_rec_end_date > DATE '2001-01-01'
)
SELECT
    i.i_category,
    w.w_state,
    sm.sm_type,
    SUM(cs.cs_net_paid)           AS total_catalog_sales,
    SUM(sr.sr_net_loss)           AS total_store_returns,
    SUM(ws.ws_net_paid)           AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
FROM catalog_sales cs
JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill   ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill  ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_bill       ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship   ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship  ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship       ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk

JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
JOIN reason r                  ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd_sr   ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr        ON sr.sr_addr_sk = ca_sr.ca_address_sk

JOIN web_sales ws             ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm_ws          ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws           ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws           ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN customer_demographics cd_ws_bill   ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill  ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer_address ca_ws_bill        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk

JOIN web_returns wr           ON wr.wr_item_sk = i.i_item_sk
JOIN reason r_wr              ON wr.wr_reason_sk = r_wr.r_reason_sk

JOIN catalog_returns cr       ON cr.cr_item_sk = i.i_item_sk
                              AND cr.cr_order_number = cs.cs_order_number
JOIN reason r_cr              ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN call_center cc_cr        ON cr.cr_call_center_sk = cc_cr.cc_call_center_sk
JOIN catalog_page cp_cr       ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
JOIN ship_mode sm_cr          ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr           ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk

JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                              AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE i.i_item_sk IN (SELECT i_item_sk FROM filtered_items)
  AND w.w_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc = 'Damaged'
  AND hd_bill.hd_buy_potential = '5001-10000'
  AND cc.cc_division = 1
GROUP BY ROLLUP (i.i_category, w.w_state, sm.sm_type)
ORDER BY i.i_category NULLS LAST,
         w.w_state NULLS LAST,
         sm.sm_type NULLS LAST
LIMIT 100
