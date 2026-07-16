SELECT
    d_sales.d_date AS sales_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    d_creation.d_month_seq AS page_creation_month_seq,
    d_access.d_day_name AS page_access_day_name,
    d_closed.d_date AS store_closed_date,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wp.wp_link_count) AS avg_page_link_count,
    AVG(wp.wp_image_count) AS avg_page_image_count
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    d_sales.d_date,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    d_creation.d_month_seq,
    d_access.d_day_name,
    d_closed.d_date
ORDER BY total_sales_amount DESC
LIMIT 100
