SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_seq,
    CASE WHEN d_sold.d_quarter_seq % 2 = 0 THEN 'Even' ELSE 'Odd' END AS quarter_parity,
    d_start.d_month_seq AS catalog_start_month,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_month_seq AS ship_month,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    d_creation.d_month_seq AS creation_month,
    d_access.d_month_seq AS access_month,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_wholesale_cost) AS gross_margin,
    SUM(ws.ws_ext_sales_price) * 0.1 AS ten_percent_of_sales,
    CONCAT(cp.cp_type, '-', s.s_state) AS type_state
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_sold.d_date_sk
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_type,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_quarter_seq,
    d_start.d_month_seq,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    wp.wp_url,
    wp.wp_type,
    wp.wp_image_count,
    d_creation.d_month_seq,
    d_access.d_month_seq
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
