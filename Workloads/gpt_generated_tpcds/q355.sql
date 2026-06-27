SELECT
    sm.sm_type AS ship_mode_type,
    td.t_shift AS time_shift,
    wh.w_state AS warehouse_state,
    wp.wp_type AS page_type,
    wsit.web_name AS site_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN warehouse wh
    ON ws.ws_warehouse_sk = wh.w_warehouse_sk
JOIN household_demographics hd
    ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE hd.hd_vehicle_count > 2
GROUP BY sm.sm_type, td.t_shift, wh.w_state, wp.wp_type, wsit.web_name
ORDER BY total_profit DESC
LIMIT 20
