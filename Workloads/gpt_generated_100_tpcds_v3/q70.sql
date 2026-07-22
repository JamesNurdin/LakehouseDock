SELECT
    d.d_year AS year,
    cc.cc_state AS state,
    wsit.web_market_manager AS market_manager,
    sm.sm_type AS ship_mode_type,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(sr.sr_return_amt) AS total_store_returns,
    AVG(ws.ws_net_profit) AS avg_net_profit,
    MAX(p.p_cost) AS max_promo_cost,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'N') AS max_active_promo_cost_global
FROM
    date_dim d
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    LEFT JOIN time_dim t
        ON t.t_time_sk = cr.cr_returned_time_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    LEFT JOIN web_site wsit
        ON wsit.web_site_sk = ws.ws_web_site_sk
WHERE
    d.d_year = 1998
    AND cc.cc_state = 'CA'
    AND wsit.web_market_manager = 'Joe George'
    AND p.p_discount_active = 'N'
    AND cp.cp_type = 'monthly'
GROUP BY
    d.d_year,
    cc.cc_state,
    wsit.web_market_manager,
    sm.sm_type
LIMIT 100
