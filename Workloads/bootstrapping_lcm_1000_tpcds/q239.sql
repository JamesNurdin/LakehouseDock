SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    d_sold.d_date AS sold_date,
    d_sold.d_year AS sold_year,
    d_end.d_date AS catalog_end_date,
    d_end.d_year AS catalog_end_year,
    s.s_store_name,
    s.s_state,
    s.s_market_id,
    s.s_number_employees,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_ext_sales_price,
    ss.ss_net_paid,
    ss.ss_ext_discount_amt,
    wp.wp_url,
    wp.wp_type,
    d_creation.d_day_name AS creation_day_name,
    d_access.d_day_name AS access_day_name,
    d_closed.d_year AS store_closed_year
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE cp.cp_type = 'Catalog'
ORDER BY cp.cp_catalog_page_id, ss.ss_quantity DESC
LIMIT 100
