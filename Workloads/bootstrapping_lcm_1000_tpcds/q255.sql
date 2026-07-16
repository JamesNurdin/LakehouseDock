SELECT
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_cp_end.d_year AS cp_end_year,
    d_cp_start.d_year AS cp_start_year,
    s.s_store_id,
    s.s_market_desc,
    d_store_closed.d_year AS store_closed_year,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_access.d_year AS page_access_year,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    d_ws_sold.d_year AS sold_year,
    d_ws_ship.d_year AS ship_year
FROM catalog_page cp
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_cp_end.d_date_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_description,
    d_cp_end.d_year,
    d_cp_start.d_year,
    s.s_store_id,
    s.s_market_desc,
    d_store_closed.d_year,
    wp.wp_url,
    wp.wp_type,
    d_wp_creation.d_year,
    d_wp_access.d_year,
    d_ws_sold.d_year,
    d_ws_ship.d_year
ORDER BY total_profit DESC
LIMIT 100
