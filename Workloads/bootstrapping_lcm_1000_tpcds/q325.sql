SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    s.s_store_name,
    s.s_state,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_shipping_delay_days,
    AVG(date_diff('day', d_promo_start.d_date, d_promo_end.d_date)) AS avg_promo_duration_days,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(p.p_cost) AS total_promo_cost,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0)) - SUM(p.p_cost)) AS net_effect,
    CASE
        WHEN SUM(ws.ws_net_paid) > 0 THEN
            (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0))) / SUM(ws.ws_net_paid)
        ELSE NULL
    END AS profit_to_sales_ratio
FROM web_sales ws
INNER JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
INNER JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_state,
    p.p_promo_name
ORDER BY sale_year, sale_month, s.s_store_name
