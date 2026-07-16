SELECT
    d_sales.d_year,
    d_sales.d_current_month,
    s.s_state,
    s.s_city,
    s.s_store_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_net_profit) AS avg_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT wp.wp_web_page_sk) AS pages_created,
    SUM(wp.wp_image_count) AS total_images,
    COUNT(DISTINCT ws.web_site_id) AS sites_opened,
    MIN(d_ws_open.d_date) AS earliest_site_open,
    MAX(d_ws_close.d_date) AS latest_site_close,
    MIN(d_store_closed.d_date) AS store_closed_date,
    MIN(d_sales.d_date) AS earliest_page_creation,
    MAX(d_wp_access.d_date) AS latest_page_access,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS state_store_rank
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sales.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
JOIN date_dim d_ws_open
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    d_sales.d_year,
    d_sales.d_current_month,
    s.s_state,
    s.s_city,
    s.s_store_id
ORDER BY total_sales DESC
LIMIT 100
