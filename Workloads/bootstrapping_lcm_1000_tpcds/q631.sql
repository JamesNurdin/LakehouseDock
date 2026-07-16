SELECT
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_creation.d_date AS page_creation_date,
    d_access.d_dow AS access_day_of_week,
    d_closed.d_year AS store_closed_year,
    hd.hd_buy_potential,
    s.s_state,
    s.s_city,
    wp.wp_type,
    wp.wp_url,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s ON 1=1
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    d_sold.d_year,
    d_ship.d_month_seq,
    d_creation.d_date,
    d_access.d_dow,
    d_closed.d_year,
    hd.hd_buy_potential,
    s.s_state,
    s.s_city,
    wp.wp_type,
    wp.wp_url
ORDER BY total_net_paid DESC
LIMIT 100
