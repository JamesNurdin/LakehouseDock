SELECT
    cp.cp_type,
    cp.cp_description,
    p.p_promo_name,
    p.p_channel_radio,
    s.s_state,
    s.s_city,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_promo_start.d_date_sk
    AND cp.cp_end_date_sk = d_promo_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    cp.cp_type,
    cp.cp_description,
    p.p_promo_name,
    p.p_channel_radio,
    s.s_state,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
