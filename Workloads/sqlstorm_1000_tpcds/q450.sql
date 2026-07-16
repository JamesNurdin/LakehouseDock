SELECT d.d_year,
       s.s_store_name,
       i.i_product_name,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       COUNT(*) AS order_count
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 1998 AND 2000
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, s.s_store_name, i.i_product_name
ORDER BY total_sales DESC
LIMIT 100
