SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_number,
    cp.cp_type,
    d_start.d_date AS catalog_start_date,
    d_end.d_date   AS catalog_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_closed.d_date AS store_closed_date,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    d_sold.d_date AS sale_date,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    wp.wp_link_count,
    d_access.d_date AS web_page_access_date,
    date_diff('day', d_start.d_date, d_access.d_date) AS days_between_catalog_start_and_web_access,
    (ss.ss_ext_sales_price - ss.ss_ext_wholesale_cost) AS gross_margin,
    (ss.ss_ext_sales_price - ss.ss_ext_wholesale_cost) / nullif(ss.ss_ext_sales_price, 0) AS gross_margin_ratio,
    ss.ss_net_profit / nullif(ss.ss_quantity, 0) AS profit_per_item
FROM catalog_page cp
JOIN date_dim d_start   ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end     ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN store_sales ss    ON ss.ss_sold_date_sk = d_end.d_date_sk
JOIN store s           ON ss.ss_store_sk     = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_sold   ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp      ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk   = d_access.d_date_sk
ORDER BY cp.cp_catalog_page_id, s.s_store_name, d_sold.d_date
LIMIT 100
