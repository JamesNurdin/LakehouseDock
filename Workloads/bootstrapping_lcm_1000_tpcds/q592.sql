SELECT
    cc.cc_name,
    cc.cc_city,
    cc.cc_manager,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
FROM store_returns sr
INNER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
INNER JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
INNER JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
INNER JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
INNER JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
INNER JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_manager,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    wp.wp_url,
    wp.wp_image_count,
    wp.wp_link_count
ORDER BY total_return_amount DESC
LIMIT 100
