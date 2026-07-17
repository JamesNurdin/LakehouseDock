/*
  Goal: Calculate total net profit, total net paid, and average discount per store and month for electronic items sold in 2001 during business hours under active promotions.
*/
SELECT
  s.s_store_name,
  month(d.d_date) AS month,
  SUM(ss.ss_net_profit) AS total_profit,
  SUM(ss.ss_net_paid) AS total_paid,
  AVG(ss.ss_ext_discount_amt) AS avg_discount
FROM store_sales ss
INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
INNER JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE i.i_category = 'Electronics'
  AND d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY s.s_store_name, month(d.d_date)
ORDER BY total_profit DESC
LIMIT 10
