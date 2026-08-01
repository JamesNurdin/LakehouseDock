WITH
  sales_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 0
  ),
  store_join AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_net_paid,
      ss.ss_net_profit,
      s.s_store_name,
      s.s_city,
      s.s_state,
      p.p_promo_name,
      hd.hd_buy_potential
    FROM sales_sample ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(s.s_store_name, '^Store [A-Z].*')
      AND p.p_promo_name LIKE '%Discount%'
  ),
  avg_profit AS (
    SELECT AVG(ss_net_profit) AS overall_avg_profit
    FROM store_sales
  )
SELECT
  s_store_name,
  p_promo_name,
  CONCAT(s_city, ', ', s_state) AS location,
  hd_buy_potential,
  COUNT(DISTINCT ss_ticket_number) AS distinct_transactions,
  SUM(ss_net_paid) AS total_net_paid,
  SUM(ss_net_profit) AS total_net_profit,
  CASE
    WHEN SUM(ss_net_profit) > (SELECT overall_avg_profit FROM avg_profit) THEN 'ABOVE_AVG'
    ELSE 'BELOW_AVG'
  END AS profit_category,
  ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS global_rank
FROM store_join
GROUP BY CUBE (s_store_name, p_promo_name, s_city, s_state, hd_buy_potential)
ORDER BY total_net_paid DESC
OFFSET 0
LIMIT 100
