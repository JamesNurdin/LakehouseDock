WITH base AS (
    SELECT
        d_sales.d_year                                            AS year,
        s.s_store_name                                            AS store_name,
        i_s.i_category                                            AS item_category,
        ss.ss_net_profit                                          AS ss_net_profit,
        sr.sr_net_loss                                            AS store_return_loss,
        cr.cr_net_loss                                            AS catalog_return_loss,
        wr.wr_net_loss                                            AS web_return_loss,
        cd.cd_purchase_estimate                                   AS cd_purchase_estimate,
        ib.ib_upper_bound                                         AS ib_upper_bound,
        c.c_customer_sk                                           AS c_customer_sk
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i_s ON ss.ss_item_sk = i_s.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN item i_r ON sr.sr_item_sk = i_r.i_item_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = ss.ss_ticket_number
                                 AND cr.cr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_cat ON cr.cr_returned_date_sk = d_cat.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = ss.ss_ticket_number
                            AND ws.ws_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
)
SELECT
    year,
    store_name,
    item_category,
    SUM(ss_net_profit)                                            AS total_net_profit,
    SUM(COALESCE(store_return_loss, 0) +
        COALESCE(catalog_return_loss, 0) +
        COALESCE(web_return_loss, 0))                             AS total_return_loss,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    SUM(cd_purchase_estimate)                                      AS total_purchase_estimate,
    MAX(ib_upper_bound)                                            AS max_income_upper_bound
FROM base
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr_ex
    WHERE wr_ex.wr_refunded_customer_sk = base.c_customer_sk
      AND wr_ex.wr_return_amt > 100
)
GROUP BY
    year,
    store_name,
    item_category
ORDER BY total_net_profit DESC
LIMIT 100
