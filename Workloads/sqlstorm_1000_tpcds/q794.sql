SELECT s.s_store_name,
       d.d_year,
       d.d_month_seq,
       cd.cd_gender,
       p.p_promo_name,
       SUM(ss.ss_net_paid) AS total_net_paid,
       SUM(ss.ss_net_profit) AS total_net_profit,
       COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY s.s_store_name, d.d_year, d.d_month_seq, cd.cd_gender, p.p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
