SELECT
    p1.p_promo_id AS promo_id,
    s1.s_store_id AS store_id,
    td1.t_hour AS hour_of_day,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    MAX(wl.web_profit_sum) AS web_total_profit_lateral,
    (SUM(ss.ss_net_profit) / NULLIF(MAX(wl.web_profit_sum), 0)) AS profit_ratio
FROM store_sales ss
JOIN store s1
    ON ss.ss_store_sk = s1.s_store_sk
JOIN promotion p1
    ON ss.ss_promo_sk = p1.p_promo_sk
JOIN time_dim td1
    ON ss.ss_sold_time_sk = td1.t_time_sk
JOIN promotion p2
    ON ss.ss_promo_sk = p2.p_promo_sk
JOIN time_dim td2
    ON ss.ss_sold_time_sk = td2.t_time_sk
JOIN store s2
    ON ss.ss_store_sk = s2.s_store_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td1.t_time_sk
JOIN promotion p3
    ON ws.ws_promo_sk = p3.p_promo_sk
JOIN time_dim td3
    ON ws.ws_sold_time_sk = td3.t_time_sk
LEFT JOIN LATERAL (
    SELECT SUM(ws2.ws_net_profit) AS web_profit_sum
    FROM web_sales ws2
    WHERE ws2.ws_promo_sk = ss.ss_promo_sk
      AND ws2.ws_sold_time_sk = ss.ss_sold_time_sk
) wl
    ON TRUE
WHERE p1.p_discount_active = 'Y'
  AND td1.t_hour BETWEEN 8 AND 12
  AND s1.s_rec_end_date > DATE '2000-01-01'
GROUP BY p1.p_promo_id, s1.s_store_id, td1.t_hour
ORDER BY profit_ratio DESC
LIMIT 100
