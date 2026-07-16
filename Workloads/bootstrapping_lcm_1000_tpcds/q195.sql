SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_current_month AS sold_month,
    d_ship.d_day_name AS ship_day,
    promotion.p_promo_name,
    promotion.p_discount_active,
    promotion.p_channel_email,
    warehouse.w_city AS warehouse_city,
    warehouse.w_state AS warehouse_state,
    warehouse.w_gmt_offset,
    store.s_city AS store_city,
    store.s_state AS store_state,
    store.s_market_desc,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(ws_quantity) AS total_qty,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_paid) AS total_net_paid,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_net_profit) / NULLIF(SUM(ws_ext_sales_price), 0) AS profit_margin
FROM web_sales
JOIN date_dim AS d_sold
    ON web_sales.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim AS d_ship
    ON web_sales.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse
    ON web_sales.ws_warehouse_sk = warehouse.w_warehouse_sk
JOIN promotion
    ON web_sales.ws_promo_sk = promotion.p_promo_sk
JOIN date_dim AS d_start
    ON promotion.p_start_date_sk = d_start.d_date_sk
JOIN date_dim AS d_end
    ON promotion.p_end_date_sk = d_end.d_date_sk
JOIN store
    ON TRUE
JOIN date_dim AS d_closed
    ON store.s_closed_date_sk = d_closed.d_date_sk
WHERE d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
  AND d_closed.d_date <= d_end.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_current_month,
    d_ship.d_day_name,
    promotion.p_promo_name,
    promotion.p_discount_active,
    promotion.p_channel_email,
    warehouse.w_city,
    warehouse.w_state,
    warehouse.w_gmt_offset,
    store.s_city,
    store.s_state,
    store.s_market_desc,
    d_start.d_date,
    d_end.d_date,
    d_closed.d_date
ORDER BY profit_margin DESC
LIMIT 100
