SELECT s.s_store_name,
       hd.hd_buy_potential,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_net_paid_inc_tax) AS total_sales,
       AVG(ss.ss_ext_discount_amt) AS avg_discount,
       COUNT(*) AS transaction_count,
       RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE s.s_state IN ('CA', 'TX', 'NY')
  AND s.s_gmt_offset > -5
  AND hd.hd_vehicle_count >= 2
  AND ss.ss_sold_date_sk BETWEEN 2459200 AND 2459565
GROUP BY s.s_store_name, hd.hd_buy_potential
HAVING SUM(ss.ss_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
