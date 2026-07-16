SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_page_number,
    d.d_year,
    d.d_current_month,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
    AND s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
    AND wp.wp_access_date_sk = d.d_date_sk
WHERE cp.cp_type = 'Catalog'
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_department,
    cp.cp_catalog_page_number,
    d.d_year,
    d.d_current_month
ORDER BY total_profit DESC
LIMIT 100
