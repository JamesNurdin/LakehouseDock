SELECT s.s_state,
       i.i_category,
       SUM(ss.ss_net_profit) AS total_profit,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_orders,
       AVG(ss.ss_ext_discount_amt) AS avg_discount
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'M'
GROUP BY s.s_state, i.i_category
ORDER BY total_sales DESC
LIMIT 100
