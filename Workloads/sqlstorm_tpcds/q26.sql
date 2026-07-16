SELECT d.d_year,
       d.d_quarter_name,
       s.s_store_name,
       i.i_category,
       p.p_promo_name,
       SUM(ss.ss_net_profit) AS total_net_profit,
       SUM(ss.ss_quantity) AS total_quantity,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_orders
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 1998
  AND p.p_discount_active = 'Y'
  AND cd.cd_education_status = 'College'
  AND hd.hd_buy_potential = '5000-9999'
GROUP BY d.d_year,
         d.d_quarter_name,
         s.s_store_name,
         i.i_category,
         p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
