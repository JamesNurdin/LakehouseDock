WITH joined_data AS (
    SELECT
        i.i_category,
        cp.cp_department,
        ca.ca_state,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_amount AS cr_return_amount,
        ss.ss_net_paid AS ss_net_paid,
        sr.sr_return_amt AS sr_return_amt,
        ws.ws_net_paid AS ws_net_paid,
        wr.wr_return_amt AS wr_return_amt
    FROM
        item i
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_order_number = cs.cs_order_number
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk

        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
        JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
        JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
        JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk

        JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
        JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
        JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
        JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
        JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    WHERE
        i.i_rec_start_date >= DATE '2001-01-01'
        AND i.i_class_id IN (1, 4)
        AND ca.ca_state = 'CA'
)
SELECT
    i_category,
    cp_department,
    ca_state,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(wr_return_amt) AS total_web_returns
FROM joined_data
GROUP BY ROLLUP(i_category, cp_department, ca_state)
HAVING SUM(cs_net_paid) > 0
ORDER BY total_catalog_sales DESC
LIMIT 100
