SELECT
  p.p_promo_id,
  p.p_promo_name,
  d.d_year,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_net_profit,
  COUNT(*) AS sales_transactions
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND p.p_cost > 500.00
  AND ca.ca_country = 'United States'
GROUP BY p.p_promo_id, p.p_promo_name, d.d_year
ORDER BY total_net_profit DESC
LIMIT 10
