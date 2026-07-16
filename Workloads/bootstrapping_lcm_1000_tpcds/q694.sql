SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    SUM(ss.ss_ext_sales_price) AS store_total_sales,
    SUM(ss.ss_net_profit) AS store_total_profit,
    SUM(ws.ws_ext_sales_price) AS web_total_sales,
    SUM(ws.ws_net_profit) AS web_total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(wp.wp_image_count) AS total_image_count,
    d_closed.d_current_year AS store_closed_year,
    d_creation.d_current_day AS web_page_creation_day,
    d_access.d_current_day AS web_page_access_day
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year = 2020
  AND s.s_state = 'TX'
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name,
    s.s_city,
    d_closed.d_current_year,
    d_creation.d_current_day,
    d_access.d_current_day
ORDER BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_name
LIMIT 100
