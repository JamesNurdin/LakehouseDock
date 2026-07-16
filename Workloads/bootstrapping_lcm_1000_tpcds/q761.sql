SELECT
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    cc.cc_name,
    d_store_closed.d_year AS store_closed_year,
    d_cc_closed.d_year AS call_center_closed_year,
    d_cc_open.d_year AS call_center_open_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    AVG(hd_refunded.hd_income_band_sk) AS avg_refunded_income_band,
    AVG(hd_returning.hd_income_band_sk) AS avg_returning_income_band,
    MIN(d_store_closed.d_date) AS first_store_closed_date,
    MAX(d_store_closed.d_date) AS last_store_closed_date
FROM store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    cc.cc_call_center_id,
    cc.cc_name,
    d_store_closed.d_year,
    d_cc_closed.d_year,
    d_cc_open.d_year
ORDER BY total_return_amount DESC, s.s_store_id
