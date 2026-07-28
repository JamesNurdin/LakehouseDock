SELECT p_promo_id,
       p_promo_name,
       p_cost
FROM tpcds.promotion
WHERE p_channel_email = 'Y'
  AND p_purpose = 'Unknown'
LIMIT 100
