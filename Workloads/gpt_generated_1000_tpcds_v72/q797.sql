SELECT
    ws.ws_order_number,
    ws.ws_net_profit,
    d_sold.d_date AS sale_date,
    ws_site.web_name,
    sm.sm_type,
    st.s_store_name,
    CASE WHEN ws.ws_quantity > 10 THEN 'Large' ELSE 'Small' END AS order_size_category,
    RANK() OVER (PARTITION BY ws_site.web_name ORDER BY ws.ws_net_profit DESC) AS profit_rank_by_site
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN store st ON st.s_closed_date_sk = d_sold.d_date_sk
WHERE
    ws.ws_ext_ship_cost > 500
    AND ws.ws_quantity BETWEEN 1 AND 20
    AND d_sold.d_year = 2001
    AND ws_site.web_market_manager = 'James Brewer'
    AND sm.sm_type = 'AIR'
    AND st.s_state = 'NY'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cr.cr_order_number = ws.ws_order_number
          AND r.r_reason_desc = 'Customer Not Satisfied'
          AND cp.cp_type = 'Promotion'
          AND cc.cc_state = 'CA'
    )
ORDER BY profit_rank_by_site
LIMIT 100
