SELECT DISTINCT
  p.p_promo_id,
  p.p_promo_name,
  p.p_channel_dmail,
  p.p_discount_active
FROM tpcds.promotion AS p
WHERE p.p_channel_dmail = 'Y'
  AND p.p_discount_active = 'N'
ORDER BY p.p_promo_id
LIMIT 100
