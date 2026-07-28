WITH cr_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cc.cc_name,
        sm.sm_type AS cr_ship_type,
        w.w_warehouse_name
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
)
SELECT
    d_ret.d_year,
    s.s_state,
    i.i_category,
    crd.cc_name,
    crd.cr_ship_type,
    sm_ws.sm_type AS ws_ship_type,
    we.web_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(crd.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount
FROM store_returns sr
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN cr_detail crd
    ON crd.cr_returned_date_sk = d_ret.d_date_sk
   AND crd.cr_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
GROUP BY GROUPING SETS (
    (d_ret.d_year, i.i_category, s.s_state, crd.cc_name, crd.cr_ship_type, sm_ws.sm_type, we.web_name),
    (d_ret.d_year, i.i_category, s.s_state, crd.cc_name, crd.cr_ship_type, sm_ws.sm_type),
    (d_ret.d_year, i.i_category, s.s_state, crd.cc_name),
    (d_ret.d_year, i.i_category),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
