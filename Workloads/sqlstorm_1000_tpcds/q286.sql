SELECT
  d.d_year,
  s.s_store_name,
  i.i_category,
  i.i_brand,
  SUM(ss.ss_net_paid) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  COUNT(DISTINCT ss.ss_ticket_number) AS num_orders
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND i.i_color = 'BLUE'
  AND s.s_market_id = 10
GROUP BY d.d_year, s.s_store_name, i.i_category, i.i_brand
ORDER BY total_sales DESC
LIMIT 100
