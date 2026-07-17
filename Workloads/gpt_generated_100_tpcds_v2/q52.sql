SELECT
    promotion.p_promo_name AS promo_name,
    d_sold.d_month_seq AS month_seq,
    t.t_shift AS shift,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN promotion
    ON ws.ws_promo_sk = promotion.p_promo_sk
JOIN date_dim d_start
    ON promotion.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON promotion.p_end_date_sk = d_end.d_date_sk
WHERE t.t_shift = 'first'
  AND d_sold.d_fy_quarter_seq = 9
  AND ws.ws_net_paid > 1000
  AND promotion.p_discount_active = 'Y'
  AND d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    promotion.p_promo_name,
    d_sold.d_month_seq,
    t.t_shift
ORDER BY total_net_paid DESC
