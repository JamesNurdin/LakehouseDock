SELECT d.d_year,
       s.s_state,
       c.c_birth_country,
       cd.cd_gender,
       i.i_category,
       t.t_hour,
       SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
       COUNT(DISTINCT ss.ss_ticket_number) AS order_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#25'
  AND p.p_channel_catalog = 'Y'
  AND cd.cd_gender = 'M'
GROUP BY d.d_year, s.s_state, c.c_birth_country, cd.cd_gender, i.i_category, t.t_hour
ORDER BY total_revenue DESC
LIMIT 100
