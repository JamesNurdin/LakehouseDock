SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_sold_date_sk) AS distinct_sales_days,
    d_closed.d_year AS store_close_year,
    d_closed.d_month_seq AS store_close_month_seq,
    ws.web_site_id,
    ws.web_name,
    d_ws_close.d_year AS site_close_year,
    d_wp_access.d_year AS page_access_year,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created,
    AVG(wp.wp_char_count) AS avg_page_char_count,
    SUM(wp.wp_link_count) AS total_page_link_count
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_closed.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_closed.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_sales.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    d_closed.d_year,
    d_closed.d_month_seq,
    ws.web_site_id,
    ws.web_name,
    d_ws_close.d_year,
    d_wp_access.d_year
ORDER BY total_ext_sales_price DESC
LIMIT 100
