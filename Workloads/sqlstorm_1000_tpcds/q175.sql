SELECT s.s_state,
       d.d_year,
       d.d_month_seq,
       i.i_category,
       cd.cd_gender,
       hd.hd_buy_potential,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
       COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       AVG(ss.ss_ext_discount_amt) AS avg_discount,
       COUNT(p.p_promo_sk) AS promo_sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
GROUP BY s.s_state,
         d.d_year,
         d.d_month_seq,
         i.i_category,
         cd.cd_gender,
         hd.hd_buy_potential
ORDER BY total_profit DESC
LIMIT 100
