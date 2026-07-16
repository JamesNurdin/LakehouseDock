SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_cc_closed.d_date AS call_center_closed_date,
    d_cc_open.d_date AS call_center_open_date,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year = 2021
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cc_closed.d_date,
    d_cc_open.d_date
ORDER BY total_return_amount DESC
LIMIT 100
