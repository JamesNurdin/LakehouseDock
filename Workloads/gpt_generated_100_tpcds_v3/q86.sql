SELECT p_channel_email,
       COUNT(*) AS promo_count,
       AVG(p_cost) AS avg_cost
FROM tpcds.promotion
WHERE p_channel_press = 'N'
  AND p_response_target = 1
GROUP BY p_channel_email
ORDER BY promo_count DESC
LIMIT 100
