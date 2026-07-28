SELECT p.p_promo_name,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       SUM(cs.cs_ext_sales_price) AS total_sales
FROM catalog_sales cs
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE cs.cs_ext_sales_price > 2000.00
  AND p.p_channel_press = 'N'
GROUP BY p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
