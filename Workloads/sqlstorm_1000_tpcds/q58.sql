SELECT d.d_year,
       i.i_category,
       i.i_brand,
       s.s_state,
       SUM(ss.ss_net_profit) AS total_profit,
       AVG(ss.ss_net_paid) AS avg_net_paid,
       COUNT(DISTINCT ss.ss_ticket_number) AS distinct_orders,
       COUNT(*) AS total_transactions
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
  AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, i.i_category, i.i_brand, s.s_state
ORDER BY total_profit DESC
LIMIT 100
