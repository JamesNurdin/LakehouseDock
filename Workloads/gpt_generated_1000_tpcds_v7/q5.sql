SELECT p.p_promo_name,
       COUNT(*) AS sales_count,
       SUM(ss.ss_net_paid) AS total_net_paid,
       AVG(ss.ss_coupon_amt) AS avg_coupon_amt
FROM promotion p
JOIN store_sales ss
  ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_channel_dmail = 'Y'
  AND ss.ss_coupon_amt > 5000
GROUP BY p.p_promo_name
ORDER BY total_net_paid DESC
LIMIT 100
