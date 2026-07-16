SELECT s_s.s_store_name,
       d_s.d_year,
       p.p_promo_name,
       SUM(ss_s.ss_net_profit) AS total_sales_profit,
       SUM(COALESCE(sr_r.sr_net_loss, 0)) AS total_return_loss,
       SUM(ss_s.ss_net_profit) - SUM(COALESCE(sr_r.sr_net_loss, 0)) AS net_profit,
       COUNT(DISTINCT ss_s.ss_ticket_number) AS sales_orders,
       COUNT(DISTINCT sr_r.sr_ticket_number) AS return_orders,
       ROUND((SUM(ss_s.ss_net_profit) - SUM(COALESCE(sr_r.sr_net_loss, 0))) / NULLIF(SUM(ss_s.ss_net_profit), 0) * 100, 2) AS profit_margin_pct
FROM store_sales ss_s
LEFT JOIN store_returns sr_r ON ss_s.ss_ticket_number = sr_r.sr_ticket_number
JOIN store s_s ON ss_s.ss_store_sk = s_s.s_store_sk
JOIN date_dim d_s ON ss_s.ss_sold_date_sk = d_s.d_date_sk
JOIN promotion p ON ss_s.ss_promo_sk = p.p_promo_sk
WHERE d_s.d_year = 2000
  AND s_s.s_state = 'CA'
GROUP BY s_s.s_store_name, d_s.d_year, p.p_promo_name
HAVING SUM(ss_s.ss_net_profit) > 10000
ORDER BY net_profit DESC
LIMIT 100
