SELECT
  p.p_promo_name,
  COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
  SUM(cs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship
FROM catalog_sales AS cs
JOIN promotion AS p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE p.p_channel_tv = 'Y'
  AND cs.cs_ext_wholesale_cost > 3000
GROUP BY p.p_promo_name
ORDER BY total_net_paid_inc_ship DESC
LIMIT 10
