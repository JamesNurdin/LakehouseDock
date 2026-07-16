SELECT
    dd_sold.d_year AS sold_year,
    dd_sold.d_current_month AS sold_month,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    p.p_channel_email,
    s.s_store_name,
    s.s_state AS store_state,
    s.s_city AS store_city,
    wsite.web_name AS website_name,
    wsite.web_state AS website_state,
    wsite.web_city AS website_city,
    dd_store.d_date AS store_closed_date,
    date_diff('day', dd_site_open.d_date, dd_site_close.d_date) AS site_lifespan_days,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_discount_amt + ws.ws_coupon_amt) AS total_discount,
    AVG(date_diff('day', dd_sold.d_date, dd_ship.d_date)) AS avg_shipping_days
FROM web_sales ws
JOIN date_dim dd_sold ON ws.ws_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim dd_promo_start ON p.p_start_date_sk = dd_promo_start.d_date_sk
JOIN date_dim dd_promo_end ON p.p_end_date_sk = dd_promo_end.d_date_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim dd_site_open ON wsite.web_open_date_sk = dd_site_open.d_date_sk
JOIN date_dim dd_site_close ON wsite.web_close_date_sk = dd_site_close.d_date_sk
CROSS JOIN store s
JOIN date_dim dd_store ON s.s_closed_date_sk = dd_store.d_date_sk
GROUP BY
    dd_sold.d_year,
    dd_sold.d_current_month,
    p.p_promo_id,
    p.p_promo_name,
    p.p_discount_active,
    p.p_channel_email,
    s.s_store_name,
    s.s_state,
    s.s_city,
    wsite.web_name,
    wsite.web_state,
    wsite.web_city,
    dd_store.d_date,
    dd_site_open.d_date,
    dd_site_close.d_date
ORDER BY total_sales DESC
LIMIT 100
