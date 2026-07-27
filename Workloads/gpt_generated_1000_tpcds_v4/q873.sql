WITH joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_net_paid,
        s.s_store_name,
        d_sales.d_year,
        i.i_category,
        i.i_item_id,
        hd.hd_income_band_sk,
        ca.ca_state,
        sr.sr_net_loss,
        r.r_reason_desc,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_net_paid AS ws_net_paid,
        wp.wp_url,
        cc.cc_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
    LEFT JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
    JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    LEFT JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
)
SELECT
    s_store_name,
    i_category,
    d_year,
    SUM(ss_net_paid) AS total_store_sales_net_paid,
    SUM(COALESCE(sr_net_loss, 0)) AS total_store_returns_net_loss,
    SUM(COALESCE(cs_net_paid, 0)) AS total_catalog_sales_net_paid,
    SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_returns_net_loss,
    SUM(COALESCE(ws_net_paid, 0)) AS total_web_sales_net_paid,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_transactions
FROM joined_data
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = joined_data.ss_item_sk
      AND ws2.ws_sold_date_sk = joined_data.ss_sold_date_sk
      AND ws2.ws_quantity > 0
)
GROUP BY s_store_name, i_category, d_year
ORDER BY total_store_sales_net_paid DESC
LIMIT 100
