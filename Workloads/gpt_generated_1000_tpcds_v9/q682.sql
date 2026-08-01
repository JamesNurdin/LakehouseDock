WITH agg_sales AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_qty
    FROM store_sales
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_sold_time_sk, ss_hdemo_sk, ss_addr_sk
),
high_activity_customers AS (
    SELECT cr_returning_customer_sk AS c_customer_sk FROM catalog_returns WHERE cr_return_quantity > 5
    UNION
    SELECT ss_customer_sk AS c_customer_sk FROM store_sales WHERE ss_quantity > 10
)
SELECT
    c.c_customer_id,
    d_sales.d_date,
    t_sales.t_hour,
    agg.total_sales,
    agg.total_qty,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cc.cc_name,
    cp.cp_department,
    sm.sm_carrier,
    wp.wp_url,
    ws.web_name,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_upper_bound,
    cr_summary.return_count,
    cr_summary.total_return_amount
FROM agg_sales agg
JOIN date_dim d_sales ON agg.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON agg.ss_sold_time_sk = t_sales.t_time_sk
JOIN customer c ON agg.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca_sales ON agg.ss_addr_sk = ca_sales.ca_address_sk
LEFT JOIN customer_address ca_current ON c.c_current_addr_sk = ca_current.ca_address_sk
LEFT JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
LEFT JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d_wp_creation.d_date_sk
LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
LEFT JOIN LATERAL (
    SELECT
        COUNT(*) AS return_count,
        SUM(cr2.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr2
    WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
) AS cr_summary ON true
WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM high_activity_customers)
  AND d_sales.d_year = 2001
GROUP BY
    c.c_customer_id,
    d_sales.d_date,
    t_sales.t_hour,
    agg.total_sales,
    agg.total_qty,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    cc.cc_name,
    cp.cp_department,
    sm.sm_carrier,
    wp.wp_url,
    ws.web_name,
    cr_summary.return_count,
    cr_summary.total_return_amount
ORDER BY agg.total_sales DESC
LIMIT 100
