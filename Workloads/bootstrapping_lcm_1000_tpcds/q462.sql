SELECT
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_market_desc,
    w.w_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(CASE WHEN ws.ws_quantity > 10 THEN ws.ws_net_profit ELSE 0 END) AS profit_large_qty,
    MIN(d_ship.d_date) AS first_ship_date,
    MAX(d_ship.d_date) AS last_ship_date,
    date_diff('day', d_start.d_date, d_end.d_date) AS promo_duration_days
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_market_desc,
    w.w_state,
    d_start.d_date,
    d_end.d_date
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
