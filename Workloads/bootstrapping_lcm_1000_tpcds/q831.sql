SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_quarter_name AS sale_quarter,
    p.p_promo_name,
    sm.sm_type AS shipping_mode,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    MAX(d_ship.d_date) AS last_ship_date
FROM web_sales ws
JOIN date_dim d_sold          ON ws.ws_sold_date_sk   = d_sold.d_date_sk
JOIN date_dim d_ship          ON ws.ws_ship_date_sk   = d_ship.d_date_sk
JOIN ship_mode sm            ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN promotion p             ON ws.ws_promo_sk       = p.p_promo_sk
JOIN date_dim d_promo_start  ON p.p_start_date_sk    = d_promo_start.d_date_sk
JOIN date_dim d_promo_end    ON p.p_end_date_sk      = d_promo_end.d_date_sk
JOIN store s                 ON s.s_closed_date_sk   = d_sold.d_date_sk
WHERE p.p_discount_active = 'Y'
  AND d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    p.p_promo_name,
    sm.sm_type,
    s.s_state
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
