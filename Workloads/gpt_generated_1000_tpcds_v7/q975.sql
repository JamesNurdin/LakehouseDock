SELECT
    s.s_store_name,
    i.i_brand,
    t.t_hour,
    wsit.web_name,
    cc.cc_class,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions
FROM store_sales ss
INNER JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
INNER JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
INNER JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
INNER JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
INNER JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
INNER JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
WHERE
    t.t_hour BETWEEN 9 AND 17
    AND i.i_category = 'Electronics'
    AND s.s_state = 'CA'
    AND w.w_state = 'TX'
    AND wsit.web_manager = 'John Ward'
    AND cc.cc_class = 'Consumer'
    AND cs.cs_quantity > 5
GROUP BY
    s.s_store_name,
    i.i_brand,
    t.t_hour,
    wsit.web_name,
    cc.cc_class
LIMIT 100
