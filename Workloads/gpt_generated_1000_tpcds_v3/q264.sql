SELECT
    cc.cc_name AS call_center_name,
    sm_cr.sm_type AS catalog_ship_mode,
    d_cr_return.d_year AS year,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    CASE
        WHEN SUM(ws.ws_net_profit) > (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) THEN 'Profit'
        ELSE 'Loss'
    END AS overall_status
FROM call_center cc
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN catalog_returns cr
    ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN date_dim d_cr_return
    ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
JOIN time_dim t_cr_return
    ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cr_return.d_date_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w_cr.w_warehouse_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold
    ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
GROUP BY
    cc.cc_name,
    sm_cr.sm_type,
    d_cr_return.d_year
ORDER BY
    total_web_net_profit DESC,
    year ASC
LIMIT 100
