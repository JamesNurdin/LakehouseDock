SELECT
  d.d_year,
  s.s_state,
  p.p_promo_name,
  SUM(ss.ss_net_profit) AS total_profit,
  SUM(COALESCE(sr.sr_net_loss, 0)) AS total_loss,
  SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_net_loss, 0)) AS net_profit
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
  AND ss.ss_store_sk = sr.sr_store_sk
WHERE p.p_channel_tv = 'Y'
  AND d.d_year BETWEEN 1997 AND 1999
GROUP BY d.d_year, s.s_state, p.p_promo_name
ORDER BY d.d_year, s.s_state, p.p_promo_name
LIMIT 100
