SELECT
  p.p_promo_id,
  p.p_promo_name,
  COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
  SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
  SUM(ss.ss_ext_discount_amt) AS total_discount_given,
  SUM(COALESCE(sr.sr_refunded_cash, 0)) AS total_refunded_cash,
  SUM(ss.ss_net_profit) - SUM(COALESCE(sr.sr_refunded_cash, 0)) AS net_profit_after_returns,
  CASE 
    WHEN SUM(ss.ss_net_paid_inc_tax) = 0 THEN 0
    ELSE SUM(COALESCE(sr.sr_refunded_cash, 0)) / SUM(ss.ss_net_paid_inc_tax)
  END AS return_rate,
  AVG(ss.ss_ext_discount_amt) AS avg_discount_per_txn
FROM store_sales ss
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
  AND ss.ss_item_sk = sr.sr_item_sk
WHERE p.p_discount_active = 'Y'
  AND p.p_cost BETWEEN 1000 AND 5000
  AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY p.p_promo_id, p.p_promo_name
HAVING SUM(ss.ss_net_paid_inc_tax) > 50000
ORDER BY net_profit_after_returns DESC
LIMIT 10
