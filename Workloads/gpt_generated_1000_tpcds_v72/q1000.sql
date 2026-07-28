WITH inv_agg AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
    GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(ss.ss_net_paid) AS store_sales_net,
    SUM(ws.ws_net_paid) AS web_sales_net,
    SUM(sr.sr_net_loss) AS store_returns_loss,
    SUM(cr.cr_net_loss) AS catalog_returns_loss,
    SUM(wr.wr_net_loss) AS web_returns_loss,
    inv_agg.total_qty_on_hand,
    (SUM(cs.cs_net_paid) + SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) -
     (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss))) AS net_revenue
FROM catalog_sales cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk

-- store sales
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_address ca_ss_addr ON ss.ss_addr_sk = ca_ss_addr.ca_address_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk

-- web sales
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk

-- store returns
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk

-- catalog returns
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk

-- web returns
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk

-- inventory aggregate
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
WHERE d_cs.d_year = 2001
  AND i.i_category = 'Sports'
  AND w_cs.w_state = 'CA'
  AND p_cs.p_discount_active = 'Y'
  AND cs.cs_quantity > 5
GROUP BY
    i.i_item_id,
    i.i_category,
    cc.cc_name,
    cp.cp_type,
    inv_agg.total_qty_on_hand
HAVING SUM(cs.cs_net_paid) > (
    SELECT AVG(cs2.cs_net_paid)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY net_revenue DESC
LIMIT 100
