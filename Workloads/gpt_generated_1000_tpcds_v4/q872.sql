WITH
    cr AS (SELECT * FROM tpcds.catalog_returns),
    cc AS (SELECT * FROM tpcds.call_center),
    cp AS (SELECT * FROM tpcds.catalog_page),
    sm_ret AS (SELECT * FROM tpcds.ship_mode),
    wh_ret AS (SELECT * FROM tpcds.warehouse),
    cust_ref AS (SELECT * FROM tpcds.customer),
    cd_ref AS (SELECT * FROM tpcds.customer_demographics),
    ws AS (SELECT * FROM tpcds.web_sales),
    sm_sale AS (SELECT * FROM tpcds.ship_mode),
    wh_sale AS (SELECT * FROM tpcds.warehouse),
    cust_bill AS (SELECT * FROM tpcds.customer),
    cd_bill AS (SELECT * FROM tpcds.customer_demographics),
    ws_site AS (SELECT * FROM tpcds.web_site)
SELECT
    cc.cc_name,
    cc.cc_state,
    ws_site.web_site_id,
    wh_sale.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS sales_orders
FROM cr
JOIN cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
JOIN wh_ret ON cr.cr_warehouse_sk = wh_ret.w_warehouse_sk
JOIN cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN ws ON ws.ws_warehouse_sk = wh_ret.w_warehouse_sk
JOIN sm_sale ON ws.ws_ship_mode_sk = sm_sale.sm_ship_mode_sk
JOIN wh_sale ON ws.ws_warehouse_sk = wh_sale.w_warehouse_sk
JOIN cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE cc.cc_state = 'CA'
  AND ws_site.web_mkt_id IN (1, 2)
GROUP BY
    cc.cc_name,
    cc.cc_state,
    ws_site.web_site_id,
    wh_sale.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
