SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  ca.ca_city,
  COUNT(*) AS transaction_count,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  CASE
    WHEN SUM(ss.ss_net_profit) > 50000 THEN 'High'
    ELSE 'Low'
  END AS profit_category,
  CONCAT(s.s_store_name, ' - ', p.p_promo_name) AS store_promo_label,
  MIN(REGEXP_EXTRACT(ca.ca_street_number, '(\\d+)', 1)) AS street_number_digits,
  MIN(REGEXP_EXTRACT(ca.ca_city, '^A(.*)town$', 1)) AS city_core,
  MIN(SUBSTRING(ca.ca_city, 1, 3)) AS city_prefix
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2001
  AND p.p_promo_name LIKE '%Clearance%'
  AND regexp_like(ca.ca_city, '^A.*town$')
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  ca.ca_city,
  p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
