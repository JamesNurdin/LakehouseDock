SELECT
    s.s_store_name,
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_days
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
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND s.s_state = 'CA'
  AND cc.cc_country = 'USA'
  AND d_sold.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date
GROUP BY
    s.s_store_name,
    cc.cc_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
