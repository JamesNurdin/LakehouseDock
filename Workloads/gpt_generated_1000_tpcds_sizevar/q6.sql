SELECT i.i_brand,
       COUNT(p.p_promo_sk) AS promo_count
FROM promotion p
JOIN item i ON p.p_item_sk = i.i_item_sk
WHERE p.p_channel_demo = 'N'
  AND i.i_current_price > 5.00
GROUP BY i.i_brand
ORDER BY promo_count DESC
LIMIT 10
