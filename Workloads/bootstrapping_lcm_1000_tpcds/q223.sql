SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_email,
    s.s_store_id,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(d_ship.d_date) AS latest_ship_date
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
JOIN store s
    ON s.s_closed_date_sk = d_promo_end.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    p.p_channel_email,
    s.s_store_id,
    s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
