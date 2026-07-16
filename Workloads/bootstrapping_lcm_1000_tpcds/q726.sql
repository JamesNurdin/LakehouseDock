SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    cp.cp_type,
    cp.cp_description,
    d_cp_end.d_year AS catalog_end_year,
    d_store_closed.d_year AS store_closed_year,
    d_wp_access.d_year AS web_page_access_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    cp.cp_type,
    cp.cp_description,
    d_cp_end.d_year,
    d_store_closed.d_year,
    d_wp_access.d_year
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
