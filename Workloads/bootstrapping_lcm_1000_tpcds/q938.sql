SELECT
    cp.cp_department,
    cp.cp_catalog_page_id,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    s.s_store_name,
    s.s_market_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT wp.wp_web_page_id) AS num_web_pages,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
    AND ss.ss_sold_date_sk = d_start.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_start.d_date_sk
    AND wp.wp_access_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_id,
    d_start.d_year,
    d_end.d_year,
    s.s_store_name,
    s.s_market_id
ORDER BY total_net_profit DESC
LIMIT 100
