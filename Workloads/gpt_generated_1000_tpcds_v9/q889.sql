WITH agg AS (
    SELECT
        s.s_store_name,
        wsite.web_site_id,
        t_time.t_hour AS sold_hour,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(ss.ss_net_paid) - SUM(COALESCE(sr.sr_net_loss, 0)) + SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_net_loss, 0)) - SUM(cr.cr_net_loss) AS total_net_contrib,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim t_time ON ss.ss_sold_time_sk = t_time.t_time_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
        LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t_time.t_time_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
        LEFT JOIN customer_address ca_wr ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_returned_time_sk = t_time.t_time_sk
        JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
        JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
        JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
    WHERE
        t_time.t_hour BETWEEN 8 AND 15
        AND s.s_state = 'CA'
        AND w_ws.w_state = 'CA'
        AND ca_ss.ca_country = 'United States'
        AND ws.ws_quantity > 0
    GROUP BY
        s.s_store_name,
        wsite.web_site_id,
        t_time.t_hour
)
SELECT
    a.s_store_name,
    a.web_site_id,
    a.sold_hour,
    a.total_net_contrib,
    RANK() OVER (PARTITION BY a.s_store_name ORDER BY a.total_net_contrib DESC) AS profit_rank,
    SUM(a.total_net_contrib) OVER (PARTITION BY a.s_store_name ORDER BY a.sold_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_contrib
FROM agg a
WHERE a.total_net_contrib > 0
ORDER BY a.total_net_contrib DESC
LIMIT 100
