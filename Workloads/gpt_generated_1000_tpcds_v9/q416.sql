SELECT
    p.p_promo_name AS promo_name,
    p.p_channel_email AS promo_channel_email,
    t.t_hour AS hour_of_day,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ws.ws_net_paid) AS web_net_paid,
    SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM store_sales ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
WHERE ss.ss_addr_sk IN (3632431, 5759226)
  AND ss.ss_list_price >= 50.00
  AND ss.ss_quantity BETWEEN 10 AND 100
  AND p.p_channel_demo = 'N'
  AND p.p_cost > 500.00
  AND t.t_hour BETWEEN 8 AND 17
  AND ws.ws_coupon_amt > 500.00
GROUP BY ROLLUP(p.p_promo_name, p.p_channel_email, t.t_hour)
HAVING SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 50000
ORDER BY total_net_paid DESC, promo_name ASC
LIMIT 100
