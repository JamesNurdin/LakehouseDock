WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        ws_site.web_name           AS site_name,
        sm.sm_type,
        w.w_warehouse_name,
        cp.cp_type,
        wp.wp_type                 AS web_page_type,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        COALESCE(sr.sr_return_amt, 0)          AS sr_return_amt,
        cr.cr_return_amount,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                                   AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cc.cc_call_center_sk = cr.cr_call_center_sk
        LEFT JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
        JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
        LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
        JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN ship_mode sm_ws ON sm_ws.sm_ship_mode_sk = ws.ws_ship_mode_sk
        LEFT JOIN warehouse w_ws ON w_ws.w_warehouse_sk = ws.ws_warehouse_sk
        LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
        LEFT JOIN web_site ws_site ON ws_site.web_site_sk = ws.ws_web_site_sk
        LEFT JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
)
SELECT
    d_year,
    d_month_seq,
    cc_name,
    site_name,
    sm_type,
    w_warehouse_name,
    cp_type,
    web_page_type,
    SUM(ss_ext_sales_price)          AS total_store_sales,
    SUM(ss_net_profit)               AS total_store_profit,
    SUM(sr_return_amt)               AS total_store_returns_amount,
    SUM(cr_return_amount)            AS total_catalog_returns_amount,
    SUM(ws_ext_sales_price)          AS total_web_sales,
    SUM(ws_net_profit)               AS total_web_profit
FROM
    base
GROUP BY
    d_year,
    d_month_seq,
    cc_name,
    site_name,
    sm_type,
    w_warehouse_name,
    cp_type,
    web_page_type
ORDER BY
    total_store_sales DESC
LIMIT 100
