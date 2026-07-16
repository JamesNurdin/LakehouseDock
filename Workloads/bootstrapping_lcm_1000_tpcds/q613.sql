SELECT
    cc.cc_company_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    d_cc_open.d_date AS call_center_open_date,
    d_cc_closed.d_date AS call_center_closed_date,
    date_diff('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_operational_days
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    r.r_reason_desc,
    d_cc_open.d_date,
    d_cc_closed.d_date
ORDER BY total_net_loss DESC
LIMIT 100
