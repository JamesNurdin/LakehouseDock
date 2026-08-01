SELECT p_purpose,
       COUNT(*) AS promo_cnt,
       AVG(p_cost) AS avg_cost
FROM promotion
WHERE p_channel_catalog = 'N'
  AND p_cost > 5000
GROUP BY p_purpose
ORDER BY avg_cost DESC
