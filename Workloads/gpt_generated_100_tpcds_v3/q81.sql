SELECT
    i.i_brand,
    i.i_category,
    sm.sm_type,
    cc.cc_state,
    td.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    AVG(ss.ss_ext_tax) AS avg_store_tax
FROM
    store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
        AND ss.ss_customer_sk = cs.cs_bill_customer_sk
        AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
        AND cs.cs_ship_customer_sk = c.c_customer_sk
        AND cs.cs_ship_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_ship_addr_sk = ca.ca_address_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
        AND ss.ss_customer_sk = ws.ws_bill_customer_sk
        AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_customer_sk = c.c_customer_sk
        AND ws.ws_ship_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_ship_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
        AND cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_returning_addr_sk = ca.ca_address_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_brand = 'Brand#23'
    AND sm.sm_type = 'AIR'
    AND td.t_hour = 12
    AND ss.ss_net_profit > (
        SELECT AVG(ss_sub.ss_net_profit)
        FROM store_sales ss_sub
        JOIN item i_sub ON ss_sub.ss_item_sk = i_sub.i_item_sk
        WHERE i_sub.i_brand = 'Brand#23'
    )
GROUP BY
    i.i_brand,
    i.i_category,
    sm.sm_type,
    cc.cc_state,
    td.t_hour
ORDER BY
    total_orders DESC,
    store_net_profit DESC
LIMIT 100
