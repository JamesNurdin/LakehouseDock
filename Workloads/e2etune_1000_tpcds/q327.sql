SELECT
  p.p_promo_name,
  p.p_channel_tv,
  p.p_channel_email,
  COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
  SUM(ss.ss_quantity) AS total_quantity,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_net_profit) AS total_net_profit,
  AVG(ss.ss_ext_discount_amt) AS avg_discount,
  AVG(ss.ss_ext_tax) AS avg_tax,
  RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank,
  (SELECT SUM(cr_return_amount) FROM catalog_returns WHERE cr_return_tax > 10) AS total_high_tax_returns
FROM store_sales ss
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
  AND p.p_start_date_sk <= ss.ss_sold_date_sk
  AND p.p_end_date_sk >= ss.ss_sold_date_sk
  AND ss.ss_net_paid > 0
GROUP BY p.p_promo_name, p.p_channel_tv, p.p_channel_email
HAVING SUM(ss.ss_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 10
