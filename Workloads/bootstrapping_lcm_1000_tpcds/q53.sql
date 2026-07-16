SELECT
    d_sold.d_year AS sales_year,
    d_sold.d_quarter_name AS sales_quarter,
    CASE WHEN d_sold.d_holiday = 'Y' THEN 'Holiday' ELSE 'NonHoliday' END AS holiday_flag,
    d_ship.d_month_seq AS ship_month_seq,
    d_creation.d_day_name AS page_creation_day,
    d_access.d_dow AS access_day_of_week,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(i.inv_quantity_on_hand) AS avg_inv_qty,
    COUNT(DISTINCT s.s_store_sk) AS num_stores_closed,
    COUNT(DISTINCT wp.wp_web_page_sk) AS num_web_pages,
    SUM(CASE WHEN wp.wp_type = 'home' THEN ws.ws_sales_price * ws.ws_quantity ELSE 0 END) AS home_page_revenue,
    SUM(CASE WHEN wp.wp_type = 'product' THEN ws.ws_sales_price * ws.ws_quantity ELSE 0 END) AS product_page_revenue,
    MAX(ws.ws_coupon_amt) AS max_coupon_amount
FROM date_dim d_sold
JOIN web_sales ws ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    CASE WHEN d_sold.d_holiday = 'Y' THEN 'Holiday' ELSE 'NonHoliday' END,
    d_ship.d_month_seq,
    d_creation.d_day_name,
    d_access.d_dow
HAVING SUM(ws.ws_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
