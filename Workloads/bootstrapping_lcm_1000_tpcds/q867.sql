SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_market_desc,
    p.p_promo_name,
    d_date.d_year AS return_year,
    d_date.d_month_seq AS return_month_seq,
    d_date.d_day_name AS return_day_name,
    d_ship.d_day_name AS ship_day_name,
    d_promo_start.d_year AS promo_start_year,
    d_promo_end.d_year AS promo_end_year,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_net_loss,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_sales_discount,
    (SUM(ws.ws_ext_sales_price) - SUM(cr.cr_return_amount)) AS net_sales_minus_returns
FROM catalog_returns cr
JOIN date_dim d_date
    ON cr.cr_returned_date_sk = d_date.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_date.d_date_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_market_desc,
    p.p_promo_name,
    d_date.d_year,
    d_date.d_month_seq,
    d_date.d_day_name,
    d_ship.d_day_name,
    d_promo_start.d_year,
    d_promo_end.d_year
ORDER BY total_return_amount DESC
LIMIT 100
