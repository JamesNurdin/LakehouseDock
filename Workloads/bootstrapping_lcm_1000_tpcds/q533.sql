SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    d_sales.d_year,
    d_sales.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(wp.wp_image_count) AS total_images,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_pages,
    MIN(d_cc_open.d_date) AS cc_open_date,
    MAX(d_cc_closed.d_date) AS cc_close_date,
    MIN(d_store_closed.d_date) AS store_close_date,
    MIN(d_wp_creation.d_date) AS page_creation_date,
    MIN(d_wp_access.d_date) AS page_access_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
