SELECT
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    d_ret.d_day_name AS return_day_name,
    t_ret.t_hour AS return_hour,
    CASE
        WHEN t_ret.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t_ret.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t_ret.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN t_ret.t_hour BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Unknown'
    END AS return_time_of_day,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_store.d_year AS store_closed_year,
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    d_cc_closed.d_year AS call_center_closed_year,
    d_cc_open.d_year AS call_center_open_year,
    d_cc_closed.d_year - d_cc_open.d_year AS call_center_years_open,
    CASE
        WHEN cr.cr_return_quantity > 5 THEN 'Large'
        ELSE 'Small'
    END AS return_size_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_amount_per_quantity,
    AVG(date_diff('day', d_store.d_date, d_ret.d_date)) AS avg_days_between_store_close_and_return,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS total_large_return_amount
FROM
    store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    CROSS JOIN catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE
    d_ret.d_year >= 2000
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    t_ret.t_hour,
    CASE
        WHEN t_ret.t_hour BETWEEN 0 AND 5 THEN 'Night'
        WHEN t_ret.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t_ret.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN t_ret.t_hour BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Unknown'
    END,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_year,
    cc.cc_name,
    cc.cc_state,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    CASE
        WHEN cr.cr_return_quantity > 5 THEN 'Large'
        ELSE 'Small'
    END
ORDER BY
    d_ret.d_year DESC,
    d_ret.d_month_seq,
    s.s_store_name,
    return_time_of_day
