SELECT
    d_sold.d_date AS sale_date,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    sm.sm_type AS ship_mode_type,
    sm.sm_carrier,
    sm.sm_contract,
    wp.wp_type AS page_type,
    wp.wp_url,
    s.s_store_id,
    s.s_city,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    ROUND(AVG(ws.ws_coupon_amt), 2) AS avg_coupon_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    DATE_DIFF('day', d_sold.d_date, d_ship.d_date) AS shipping_days,
    d_creation.d_date AS page_creation_date,
    d_access.d_date AS page_access_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_type,
    sm.sm_carrier,
    sm.sm_contract,
    wp.wp_type,
    wp.wp_url,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_ship.d_date,
    d_creation.d_date,
    d_access.d_date
ORDER BY total_sales_amount DESC
LIMIT 100
