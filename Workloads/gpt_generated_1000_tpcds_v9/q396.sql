SELECT
    cc.cc_name AS call_center_name,
    cp.cp_department AS department,
    i.i_category AS item_category,
    p_cs.p_promo_name AS catalog_promotion,
    p_ss.p_promo_name AS store_promotion,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name AS warehouse_name,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_tickets
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.promotion p_ss
    ON ss.ss_promo_sk = p_ss.p_promo_sk
WHERE
    cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_rec_start_date <= DATE '2000-12-31'
GROUP BY
    cc.cc_name,
    cp.cp_department,
    i.i_category,
    p_cs.p_promo_name,
    p_ss.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name
HAVING
    SUM(cs.cs_net_profit) > 10000
ORDER BY
    total_catalog_net_profit DESC
LIMIT 100
