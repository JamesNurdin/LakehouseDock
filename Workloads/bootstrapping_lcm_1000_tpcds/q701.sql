SELECT
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    p.p_promo_name AS promo_name,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    COUNT(DISTINCT ws.ws_order_number) AS orders_sold,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid) AS total_sales_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT wr.wr_order_number) AS orders_returned,
    SUM(wr.wr_return_quantity) AS total_quantity_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(date_diff('day', d_sold.d_date, d_return.d_date)) AS avg_days_to_return,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_margin,
    (COUNT(DISTINCT wr.wr_order_number) * 100.0 / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0)) AS return_rate_percent,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month
FROM web_sales ws
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_promo_start.d_date,
    d_promo_end.d_date
ORDER BY net_margin DESC
LIMIT 100
