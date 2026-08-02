WITH unified_data AS (
    SELECT
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        d_ss.d_year AS year,
        p.p_promo_name AS promo_name,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_qty,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
        CASE WHEN sr.sr_net_loss > 0 THEN 1 ELSE 0 END AS store_loss_flag,
        (SELECT MAX(p2.p_start_date_sk) FROM promotion p2 WHERE p2.p_response_target > 0) AS max_promo_start_sk
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    CROSS JOIN LATERAL (
        SELECT cc.cc_mkt_id, cc.cc_mkt_class
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
    ) cc_l
    CROSS JOIN LATERAL (
        SELECT cp.cp_department, cp.cp_description
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) cp_l
    WHERE
        d_ss.d_year = 2001
        AND t_ss.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND w.w_state = 'TX'
        AND p.p_response_target = 1
        AND cc_l.cc_mkt_id = 5
        AND we.web_class = 'M'
        AND cp_l.cp_department = 'Electronics'
        AND p.p_channel_press = 'N'

    UNION

    SELECT
        s.s_store_name AS store_name,
        s.s_state AS store_state,
        d_ss.d_year AS year,
        p.p_promo_name AS promo_name,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
        COALESCE(cr.cr_return_quantity, 0) AS catalog_return_qty,
        COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
        CASE WHEN sr.sr_net_loss > 0 THEN 1 ELSE 0 END AS store_loss_flag,
        (SELECT MAX(p2.p_start_date_sk) FROM promotion p2 WHERE p2.p_response_target > 0) AS max_promo_start_sk
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    CROSS JOIN LATERAL (
        SELECT cc.cc_mkt_id, cc.cc_mkt_class
        FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
    ) cc_l
    CROSS JOIN LATERAL (
        SELECT cp.cp_department, cp.cp_description
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) cp_l
    WHERE
        d_ss.d_year = 2001
        AND t_ss.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND w.w_state = 'TX'
        AND p.p_response_target = 1
        AND cc_l.cc_mkt_id = 5
        AND we.web_class = 'M'
        AND cp_l.cp_department = 'Electronics'
        AND p.p_channel_press = 'Y'
)
SELECT
    store_name,
    store_state,
    promo_name,
    year,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(store_return_qty) AS total_store_return_qty,
    SUM(catalog_return_qty) AS total_catalog_return_qty,
    SUM(web_return_qty) AS total_web_return_qty,
    SUM(store_loss_flag) AS total_store_loss_count,
    MAX(max_promo_start_sk) AS max_promo_start_sk
FROM unified_data
GROUP BY store_name, store_state, promo_name, year
ORDER BY total_net_paid DESC
LIMIT 100
