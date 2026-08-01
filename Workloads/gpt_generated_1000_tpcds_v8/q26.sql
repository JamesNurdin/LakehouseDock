SELECT
    p.p_promo_name,
    p.p_channel_press,
    SUM(ss.ss_net_profit) AS total_net_profit
FROM tpcds.store_sales ss
JOIN tpcds.promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_cost = 1000.00
  AND ss.ss_net_profit > 0
GROUP BY p.p_promo_name, p.p_channel_press
ORDER BY total_net_profit DESC
LIMIT 100
