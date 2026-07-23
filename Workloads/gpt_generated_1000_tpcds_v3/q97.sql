WITH joined_data AS (
    SELECT
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        d.d_date AS d_date,
        t.t_hour AS t_hour,
        c.c_customer_sk AS c_customer_sk,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        ca.ca_state AS ca_state,
        hd.hd_income_band_sk AS hd_income_band_sk,
        hd.hd_buy_potential AS hd_buy_potential,
        hd.hd_dep_count AS hd_dep_count,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        r.r_reason_desc AS r_reason_desc,
        cc.cc_name AS cc_name,
        w.w_state AS warehouse_state,
        we.web_state AS web_site_state,
        wp.wp_type AS wp_type,
        CASE WHEN hd.hd_dep_count > 3 THEN 'Large' ELSE 'Small' END AS household_category
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    JOIN customer_address ca ON ca.ca_address_sk = ss.ss_addr_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
    JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq = 12
        AND hd.hd_income_band_sk IN (1, 9, 17)
        AND hd.hd_buy_potential = '1001-5000'
        AND cc.cc_gmt_offset = -8.00
        AND w.w_state = 'CA'
        AND ws.ws_quantity > 10
        AND cs.cs_quantity > 5
        AND cr.cr_net_loss > 100.00
        AND r.r_reason_desc = 'Customer Not Satisfied'
        AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    d_year,
    d_month_seq,
    warehouse_state,
    household_category,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(cs_net_profit) AS total_catalog_profit,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(ss_net_profit + cs_net_profit + ws_net_profit) AS total_combined_profit,
    COUNT(*) AS transaction_count,
    AVG(CASE WHEN cr_return_quantity > 0 THEN cr_return_amount ELSE NULL END) AS avg_return_amount,
    SUM(CASE WHEN hd_dep_count > 3 THEN cr_net_loss ELSE 0 END) AS total_large_household_loss
FROM joined_data
GROUP BY
    d_year,
    d_month_seq,
    warehouse_state,
    household_category
HAVING
    SUM(ss_net_profit + cs_net_profit + ws_net_profit) > 50000
ORDER BY
    total_combined_profit DESC
LIMIT 100
