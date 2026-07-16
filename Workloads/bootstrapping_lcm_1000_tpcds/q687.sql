SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    COUNT(DISTINCT cr.cr_order_number) AS total_orders_returned,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    MIN(d_open.d_date) AS call_center_open_date,
    MAX(d_close.d_date) AS call_center_close_date,
    MAX(d_access.d_date) AS latest_web_page_access_date,
    wp.wp_url,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created_on_return_date,
    SUM(wp.wp_link_count) AS total_links_in_pages
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON cc.cc_closed_date_sk = d_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ret.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_ret.d_year = 2001
GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_city,
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    wp.wp_url
ORDER BY total_net_loss DESC
LIMIT 100
