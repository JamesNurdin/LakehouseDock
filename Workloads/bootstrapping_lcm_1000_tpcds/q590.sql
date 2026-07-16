SELECT
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date AS cc_open_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_date AS return_date,
    t.t_hour,
    t.t_meal_time,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
    COUNT(*) AS num_returns
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_date,
    t.t_hour,
    t.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100
