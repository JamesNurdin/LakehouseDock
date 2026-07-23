WITH high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 50000
)
SELECT
    i.i_category,
    i.i_brand,
    dd_ss.d_year,
    td_ss.t_shift,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(ss.ss_quantity) AS avg_quantity,
    MAX(ss.ss_ext_wholesale_cost) AS max_wholesale_cost,
    MIN(ss.ss_ext_wholesale_cost) AS min_wholesale_cost,
    cc.cc_name,
    ws.web_name
FROM store_sales ss
JOIN date_dim dd_ss ON ss.ss_sold_date_sk = dd_ss.d_date_sk
JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_hdemo_sk = hd.hd_demo_sk
    AND sr.sr_addr_sk = ca.ca_address_sk
JOIN date_dim dd_sr ON sr.sr_returned_date_sk = dd_sr.d_date_sk
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
CROSS JOIN call_center cc
JOIN date_dim dd_cc_open ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN date_dim dd_cc_close ON cc.cc_closed_date_sk = dd_cc_close.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim dd_cp_start ON cp.cp_start_date_sk = dd_cp_start.d_date_sk
JOIN date_dim dd_cp_end ON cp.cp_end_date_sk = dd_cp_end.d_date_sk
CROSS JOIN web_site ws
JOIN date_dim dd_ws_open ON ws.web_open_date_sk = dd_ws_open.d_date_sk
JOIN date_dim dd_ws_close ON ws.web_close_date_sk = dd_ws_close.d_date_sk
JOIN date_dim dd_c_first_ship ON c.c_first_shipto_date_sk = dd_c_first_ship.d_date_sk
JOIN date_dim dd_c_first_sales ON c.c_first_sales_date_sk = dd_c_first_sales.d_date_sk
WHERE
    dd_ss.d_fy_year = 1915
    AND td_ss.t_shift = 'first'
    AND i.i_current_price >= 100.00
    AND ib.ib_lower_bound >= 50000
    AND cc.cc_state = 'CA'
    AND ws.web_country = 'United States'
    AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_quantity > 0
    )
    AND c.c_customer_sk IN (SELECT c_customer_sk FROM high_income_customers)
GROUP BY
    i.i_category,
    i.i_brand,
    dd_ss.d_year,
    td_ss.t_shift,
    cc.cc_name,
    ws.web_name
ORDER BY total_sales DESC
LIMIT 100
