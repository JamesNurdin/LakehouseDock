SELECT
    s.s_store_id,
    s.s_state,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    d_store_closed.d_month_seq AS store_closed_month_seq,
    t.t_meal_time,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    AVG(t.t_hour) AS avg_hour_of_day,
    SUM(wp.wp_image_count) AS total_images,
    SUM(wp.wp_link_count) AS total_links,
    AVG(s.s_tax_percentage) AS avg_tax_pct,
    MIN(d_page_creation.d_date) AS first_page_creation_date,
    MAX(d_page_access.d_date) AS last_page_access_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_state,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    d_store_closed.d_month_seq,
    t.t_meal_time,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
