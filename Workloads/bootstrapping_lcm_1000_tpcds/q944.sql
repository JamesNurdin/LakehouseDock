SELECT
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_sold.d_date AS sold_date,
    dd_ship.d_date AS ship_date,
    p.p_promo_name,
    p.p_discount_active,
    dd_start.d_date AS promo_start_date,
    dd_end.d_date AS promo_end_date,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    w.w_warehouse_name,
    w.w_city AS warehouse_city,
    w.w_state AS warehouse_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(*) AS order_count
FROM web_sales ws
JOIN date_dim dd_sold
    ON ws.ws_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
    ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim dd_start
    ON p.p_start_date_sk = dd_start.d_date_sk
JOIN date_dim dd_end
    ON p.p_end_date_sk = dd_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dd_sold.d_date_sk
GROUP BY
    dd_sold.d_year,
    dd_sold.d_month_seq,
    dd_sold.d_date,
    dd_ship.d_date,
    p.p_promo_name,
    p.p_discount_active,
    dd_start.d_date,
    dd_end.d_date,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    w.w_warehouse_name,
    w.w_city,
    w.w_state
ORDER BY total_sales DESC
LIMIT 100
