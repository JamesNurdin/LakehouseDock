SELECT p_channel_email,
       COUNT(*) AS promo_cnt,
       SUM(p_cost) AS total_cost
FROM tpcds.promotion
WHERE p_channel_email = 'Y'
  AND p_cost > 100.00
GROUP BY p_channel_email
ORDER BY promo_cnt DESC
