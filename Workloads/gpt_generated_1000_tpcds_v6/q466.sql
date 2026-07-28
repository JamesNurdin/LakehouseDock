WITH base AS (
    SELECT
        s.s_store_name,
        i.i_category,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS store_profit_status
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND td_cr.t_hour = 14
      AND i.i_category = 'Electronics'
    GROUP BY s.s_store_name, i.i_category, r.r_reason_desc
)
SELECT *
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
