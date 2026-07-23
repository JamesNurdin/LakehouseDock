WITH date_info AS (
    SELECT d_date_sk, d_year, d_date
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    d.d_year AS return_year,
    ca_sr.ca_state AS state,
    SUM(sr.sr_return_amt) AS store_return_amount,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount
FROM date_info d
JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
JOIN customer_address ca_cr_ref ON cr.cr_refunded_addr_sk = ca_cr_ref.ca_address_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_info d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
GROUP BY d.d_year, ca_sr.ca_state
ORDER BY d.d_year DESC, ca_sr.ca_state
LIMIT 100
