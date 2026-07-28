SELECT
    i.i_category,
    p.p_channel_email,
    SUM(ss.ss_net_paid) AS total_sales_net,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
    AVG(inv1.inv_quantity_on_hand) AS avg_qty_warehouse1,
    AVG(inv2.inv_quantity_on_hand) AS avg_qty_warehouse2,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales,
    SUM(ss.ss_net_profit) AS total_profit
FROM tpcds.store_sales ss
JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN tpcds.customer cust
    ON ss.ss_customer_sk = cust.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.inventory inv1
    ON i.i_item_sk = inv1.inv_item_sk
JOIN tpcds.inventory inv2
    ON i.i_item_sk = inv2.inv_item_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN tpcds.ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN tpcds.customer cust_ref
    ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
WHERE i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
GROUP BY i.i_category, p.p_channel_email
ORDER BY total_sales_net DESC
LIMIT 100
