SELECT
    cc.cc_state,
    cc.cc_division_name,
    s.s_state,
    s.s_city,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_year AS ship_year,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(ws.ws_coupon_amt) AS min_coupon_amt,
    MAX(ws.ws_net_paid_inc_ship_tax) AS max_payment,
    AVG(date_diff('day', d_wp_creation.d_date, d_wp_access.d_date)) AS avg_page_lifecycle_days
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    cc.cc_state,
    cc.cc_division_name,
    s.s_state,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
