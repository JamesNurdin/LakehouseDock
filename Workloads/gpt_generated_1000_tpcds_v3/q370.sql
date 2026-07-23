SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    SUM(cs.cs_net_profit) AS sum_catalog_net_profit,
    SUM(ws.ws_net_profit) AS sum_web_net_profit,
    SUM(ss.ss_net_profit) AS sum_store_net_profit,
    SUM(cr.cr_net_loss) AS sum_catalog_returns_loss,
    SUM(wr.wr_net_loss) AS sum_web_returns_loss,
    SUM(sr.sr_net_loss) AS sum_store_returns_loss,
    CASE WHEN (
        SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)
        - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss) - SUM(sr.sr_net_loss)
    ) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM tpcds.item i
-- promotion linked directly to the item
JOIN tpcds.promotion p ON i.i_item_sk = p.p_item_sk
-- catalog channel
JOIN tpcds.catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
JOIN tpcds.customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN tpcds.customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN tpcds.customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN tpcds.warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
JOIN tpcds.promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
-- catalog returns linked to the same order and item
JOIN tpcds.catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    AND i.i_item_sk = cr.cr_item_sk
JOIN tpcds.reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
-- web channel
JOIN tpcds.web_sales ws ON i.i_item_sk = ws.ws_item_sk
JOIN tpcds.customer cust_ws_bill ON ws.ws_bill_customer_sk = cust_ws_bill.c_customer_sk
JOIN tpcds.customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN tpcds.customer cust_ws_ship ON ws.ws_ship_customer_sk = cust_ws_ship.c_customer_sk
JOIN tpcds.customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN tpcds.ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN tpcds.warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN tpcds.promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site site ON ws.ws_web_site_sk = site.web_site_sk
-- web returns
JOIN tpcds.web_returns wr ON ws.ws_order_number = wr.wr_order_number
    AND i.i_item_sk = wr.wr_item_sk
JOIN tpcds.reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
-- store channel
JOIN tpcds.store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN tpcds.customer cust_ss ON ss.ss_customer_sk = cust_ss.c_customer_sk
JOIN tpcds.customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN tpcds.promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
-- store returns
JOIN tpcds.store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    AND i.i_item_sk = sr.sr_item_sk
JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
WHERE EXISTS (
    SELECT 1 FROM tpcds.inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk
      AND inv.inv_quantity_on_hand > 0
)
GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category
ORDER BY (
    SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) + SUM(ss.ss_net_profit)
    - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss) - SUM(sr.sr_net_loss)
) DESC
LIMIT 100
